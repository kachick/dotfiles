package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path"
	"strings"

	"github.com/kachick/dotfiles/internal/githooks"
	pipeline "github.com/mattn/go-pipeline"
)

var (
	TyposConfigPath string
)

// Spec of Git: https://git-scm.com/docs/githooks#_pre_push
func main() {
	log.SetFlags(log.Flags() &^ (log.Ldate | log.Ltime))

	remoteDefaultBranch, err := getRemoteDefaultBranch()
	if err != nil {
		log.Fatalln("Can't get default branch of the remote repository")
	}

	shouldSkip := githooks.MakeSkipChecker()

	scanner := bufio.NewScanner(os.Stdin)
	linters := map[string]githooks.Linter{}
	lineNumber := 0
	for scanner.Scan() {
		line := scanner.Text()
		lineNumber += 1
		lintersForEntry, err := initializeLinters(line, remoteDefaultBranch)
		if err != nil {
			fmt.Println("Error:", err)
		}
		for desc, linter := range lintersForEntry {
			linters[fmt.Sprintf("L%d:%s:%s", lineNumber, line, desc)] = linter
		}
	}

	if err := scanner.Err(); err != nil {
		fmt.Println("Error reading input:", err)
		os.Exit(1)
	}

	if err := githooks.RunLinters(linters, shouldSkip); err != nil {
		log.Fatalf("Failed to run global hook: %+v", err)
	}

	// Don't include localhooks into above parallel tasks, because of we don't assume local hooks are not having any side-effect
	if shouldSkip("localhook") {
		return
	}

	if err := runLocalHook(); err != nil {
		log.Fatalf("Failed to run local hook: %+v", err)
	}
}

func initializeLinters(line string, remoteBranch string) (map[string]githooks.Linter, error) {
	fields := strings.Fields(line)
	if len(fields) != 4 {
		return nil, fmt.Errorf("parsing error for given line: %s", line)
	}

	localRef := fields[0]
	// localOid := fields[1]
	remoteRef := fields[2]
	// remoteOid := fields[3]

	return map[string]githooks.Linter{
		"prevent secrets in log and diff": githooks.Linter{Tag: "gitleaks", Script: func() error {
			cmd := exec.Command("gitleaks", "--verbose", "git", fmt.Sprintf("--log-opts=%s..%s", remoteBranch, localRef))
			out, err := cmd.CombinedOutput()
			log.Println(strings.Join(cmd.Args, " "))
			log.Println(string(out))
			return err
		}},
		"prevent typos in log and diff": githooks.Linter{Tag: "typos", Script: func() error {
			out, err := pipeline.CombinedOutput(
				[]string{"git", "log", "--patch", fmt.Sprintf("%s..%s", remoteBranch, localRef)},
				[]string{"typos", "--config", TyposConfigPath, "-"},
			)
			log.Println(string(out))
			return err
		}},
		"prevent typos in branch name": githooks.Linter{Tag: "typos", Script: func() error {
			cmd := exec.Command("typos", "--config", TyposConfigPath, "-")
			// Git ref is not a filepath, but avoiding a typos limitation for slash included strings
			// See https://github.com/crate-ci/typos/issues/758 for detail
			cmd.Stdin = strings.NewReader(path.Base(remoteRef))
			out, err := cmd.CombinedOutput()
			log.Println(string(out))
			return err
		}},
	}, nil
}

func getRemoteDefaultBranch() (string, error) {
	cmd := exec.Command("git", "symbolic-ref", "refs/remotes/origin/HEAD")
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get remote default branch: %w", err)
	}
	return strings.TrimSpace(string(out)), nil
}

// Don't run global and local hooks together in parallel tasks, because of we don't assume local hooks do not have any side-effect
func runLocalHook() error {
	cmd := exec.Command("run_local_hook", append([]string{"pre-push"}, os.Args[1:]...)...)
	cmd.Stdin = os.Stdin
	out, err := cmd.CombinedOutput()
	log.Println(string(out))
	return err
}
