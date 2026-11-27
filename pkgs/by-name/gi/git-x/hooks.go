package main

import (
	"bufio"
	"bytes"
	"flag"
	"fmt"
	"io"
	"log"
	"os/exec"
	"path"
	"strings"

	"github.com/kachick/dotfiles/pkgs/by-name/gi/git-x/internal/githooks"
)

// TyposConfigPath is injected at build time via `-X main.TyposConfigPath=...`.
var TyposConfigPath string

func allHooksPrePushSubcommands() []cliCommandSpec {
	return []cliCommandSpec{
		{name: "betterleaks", description: "Prevent secrets in commits (log and diff)"},
		{name: "typos-commits", description: "Prevent typos in commits (log and diff)"},
		{name: "typos-branch", description: "Prevent typos in branch names"},
	}
}

func allHooksEvents() []cliCommandSpec {
	return []cliCommandSpec{
		{
			name:        "pre-push",
			description: "Run pre-push checks (betterleaks, typos-commits, typos-branch)",
			subcommands: allHooksPrePushSubcommands(),
		},
	}
}

func printHooksUsage(w io.Writer) {
	fmt.Fprintf(w, "Usage: git x hooks <hook-event> <subcommand>\n\n")
	fmt.Fprintf(w, "Hook events:\n")
	for _, ev := range allHooksEvents() {
		fmt.Fprintf(w, "  %-10s%s\n", ev.name, ev.description)
	}
}

func printPrePushUsage(w io.Writer) {
	fmt.Fprintf(w, "Usage: git x hooks pre-push <subcommand>\n\n")
	fmt.Fprintf(w, "Subcommands:\n")
	for _, sub := range allHooksPrePushSubcommands() {
		fmt.Fprintf(w, "  %-15s%s\n", sub.name, sub.description)
	}
}

func runHooks(args []string, stdin io.Reader, stdout, stderr io.Writer) error {
	if len(args) == 0 {
		printHooksUsage(stderr)
		return flag.ErrHelp
	}
	switch args[0] {
	case "-h", "--help":
		printHooksUsage(stderr)
		return flag.ErrHelp
	case "help":
		printHooksUsage(stdout)
		return nil
	case "pre-push":
		return runHooksPrePush(args[1:], stdin, stdout, stderr)
	default:
		printHooksUsage(stderr)
		return fmt.Errorf("unknown hook event: %s", args[0])
	}
}

// Spec of Git: https://git-scm.com/docs/githooks#_pre_push
func runHooksPrePush(args []string, stdin io.Reader, _, stderr io.Writer) error {
	if len(args) == 0 {
		printPrePushUsage(stderr)
		return flag.ErrHelp
	}

	subcommand := args[0]
	switch subcommand {
	case "-h", "--help":
		printPrePushUsage(stderr)
		return flag.ErrHelp
	}
	validSubcommand := false
	for _, sub := range allHooksPrePushSubcommands() {
		if sub.name == subcommand {
			validSubcommand = true
			break
		}
	}
	if !validSubcommand {
		printPrePushUsage(stderr)
		return fmt.Errorf("unknown pre-push subcommand: %s", subcommand)
	}

	log.SetOutput(stderr)
	log.SetFlags(log.Flags() &^ (log.Ldate | log.Ltime))

	remoteDefaultBranch, err := getRemoteDefaultBranch()
	if err != nil {
		return fmt.Errorf("can't get default branch of the remote repository: %w", err)
	}
	email, err := getEmail()
	if err != nil {
		return fmt.Errorf("can't get git email: %w", err)
	}

	scanner := bufio.NewScanner(stdin)
	linters := map[string]githooks.Linter{}
	lineNumber := 0
	for scanner.Scan() {
		line := scanner.Text()
		lineNumber += 1
		lintersForEntry, err := initializeLinters(line, remoteDefaultBranch, email)
		if err != nil {
			fmt.Fprintln(stderr, "Error:", err)
		}
		for desc, linter := range lintersForEntry {
			if linter.Tag == subcommand {
				linters[fmt.Sprintf("L%d:%s:%s", lineNumber, line, desc)] = linter
			}
		}
	}

	if err := scanner.Err(); err != nil {
		return fmt.Errorf("error reading input: %w", err)
	}

	if err := githooks.RunLinters(linters); err != nil {
		return fmt.Errorf("failed to run global hook: %w", err)
	}
	return nil
}

const (
	zeroOIDSHA1   = "0000000000000000000000000000000000000000"
	zeroOIDSHA256 = "0000000000000000000000000000000000000000000000000000000000000000"
)

// Filtering with author email for large repository such as NixOS/nixpkgs
func initializeLinters(line string, remoteBranch string, email string) (map[string]githooks.Linter, error) {
	fields := strings.Fields(line)
	if len(fields) != 4 {
		return nil, fmt.Errorf("parsing error for given line: %s", line)
	}

	localRef := fields[0]
	localOid := fields[1]
	remoteRef := fields[2]

	// In Git githooks(5), a deleted ref supplies "(delete)" in <local-ref> and the all-zero object name in <local-oid>.
	// Skip deleted refs so commands like "git log" do not fail with an invalid revision.
	if localRef == "(delete)" || localOid == zeroOIDSHA1 || localOid == zeroOIDSHA256 {
		return nil, nil
	}

	return map[string]githooks.Linter{
		"prevent secrets in log and diff": {Tag: "betterleaks", Script: func() error {
			// NOTE: betterleaks runs `git log -p` without `--no-textconv` and `--no-ext-diff`.
			// Repositories with textconv enabled (for example, `*.gpg diff=gpg`) decrypt files during scans,
			// causing false positive leaks on encrypted secrets.
			// Upstream is addressing this in https://github.com/betterleaks/betterleaks/pull/401.
			// For now, repositories with such setups can bypass this hook with:
			//   git config set hook.pre-push-no-leaks.enabled false
			cmd := exec.Command("betterleaks", "--verbose", "git", fmt.Sprintf("--log-opts=--author=%s %s..%s", email, remoteBranch, localRef))
			out, err := cmd.CombinedOutput()
			log.Println(strings.Join(cmd.Args, " "))
			log.Println(string(out))
			if err != nil {
				return err
			}

			// TODO: betterleaks v1 does not scan commit messages with the "git" subcommand.
			// Consider replacing this separate stdin scan with --include=commit-messages when upgrading to betterleaks v2.
			msgOut, msgErr := runPipedCommands(
				[]string{"git", "log", "--author=" + email, "--format=%B", fmt.Sprintf("%s..%s", remoteBranch, localRef)},
				[]string{"betterleaks", "--verbose", "stdin"},
			)
			log.Println(string(msgOut))
			return msgErr
		}},
		"prevent typos in log and diff": {Tag: "typos-commits", Script: func() error {
			out, err := checkCommitsTypos(remoteBranch, localRef, email)
			log.Println(string(out))
			return err
		}},
		"prevent typos in branch name": {Tag: "typos-branch", Script: func() error {
			cmd := exec.Command("typos", "--config", TyposConfigPath, "-")
			// Git ref is not a filepath, but avoiding a typos limitation for slash included strings
			// See https://github.com/crate-ci/typos/issues/758 for details
			cmd.Stdin = strings.NewReader(path.Base(remoteRef))
			out, err := cmd.CombinedOutput()
			log.Println(string(out))
			return err
		}},
	}, nil
}

// Why not pipe `git log --patch` directly into `typos`:
// Git truncates hunk header context (`@@ ... @@ <funcname>`) at 80 bytes, which cuts
// unchanged identifiers mid-word (such as cutting "error" to 4 chars) and triggers false positives.
// Feeding commit messages and added `+` lines separately also prevents deleted lines from
// failing commits that fix existing typos.
func checkCommitsTypos(remoteBranch, localRef, email string) ([]byte, error) {
	revRange := fmt.Sprintf("%s..%s", remoteBranch, localRef)
	messages, err := runCommandStdout([]string{"git", "log", "--author=" + email, "--format=%B", revRange})
	if err != nil {
		return messages, err
	}

	patch, err := runCommandStdout([]string{
		"git", "log", "--no-ext-diff", "--no-textconv",
		"--author=" + email, "--format=", "--patch", "--unified=0", revRange,
	})
	if err != nil {
		return patch, err
	}

	addedDiff, err := extractAddedDiffLines(bytes.NewReader(patch))
	if err != nil {
		return nil, err
	}

	var input bytes.Buffer
	input.Write(messages)
	if len(messages) > 0 && !bytes.HasSuffix(messages, []byte("\n")) {
		input.WriteByte('\n')
	}
	input.Write(addedDiff)

	cmd := exec.Command("typos", "--config", TyposConfigPath, "-")
	cmd.Stdin = &input
	return cmd.CombinedOutput()
}

func extractAddedDiffLines(r io.Reader) ([]byte, error) {
	reader := bufio.NewReader(r)
	var out bytes.Buffer
	inHunk := false

	for {
		line, err := reader.ReadString('\n')
		if err != nil && err != io.EOF {
			return nil, err
		}
		if len(line) > 0 {
			trimmed := strings.TrimRight(line, "\r\n")
			switch {
			case strings.HasPrefix(trimmed, "diff "):
				inHunk = false
			case strings.HasPrefix(trimmed, "@@ "), strings.HasPrefix(trimmed, "@@@ "):
				inHunk = true
			case inHunk && strings.HasPrefix(trimmed, "+"):
				out.WriteString(trimmed[1:])
				out.WriteByte('\n')
			}
		}
		if err == io.EOF {
			break
		}
	}

	return out.Bytes(), nil
}

func runCommandStdout(args []string) ([]byte, error) {
	cmd := exec.Command(args[0], args[1:]...)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		return stderr.Bytes(), err
	}
	return stdout.Bytes(), nil
}

// Why not external pipeline libraries:
// Running the first command and passing its stdout buffer to the second command's stdin
// handles two-stage git log checks with standard os/exec alone.
func runPipedCommands(firstArgs []string, secondArgs []string) ([]byte, error) {
	stdout, err := runCommandStdout(firstArgs)
	if err != nil {
		return stdout, err
	}

	second := exec.Command(secondArgs[0], secondArgs[1:]...)
	second.Stdin = bytes.NewReader(stdout)
	return second.CombinedOutput()
}

func getRemoteDefaultBranch() (string, error) {
	cmd := exec.Command("git", "symbolic-ref", "refs/remotes/origin/HEAD")
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get remote default branch: %w", err)
	}
	return strings.TrimSpace(string(out)), nil
}

func getEmail() (string, error) {
	cmd := exec.Command("git", "config", "user.email")
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get git email: %w", err)
	}
	return strings.TrimSpace(string(out)), nil
}
