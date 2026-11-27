package main

import (
	"bufio"
	"bytes"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"

	"github.com/kachick/dotfiles/pkgs/by-name/gi/git-x/internal/gitcmd"
)

func trimHistoryLines(r io.Reader) string {
	scanner := bufio.NewScanner(r)
	var lines []string
	for scanner.Scan() {
		trimmed := strings.TrimSpace(scanner.Text())
		if trimmed != "" {
			lines = append(lines, trimmed)
		}
	}
	if len(lines) == 0 {
		return ""
	}
	return strings.Join(lines, "\n") + "\n"
}

func formatBacktickCommitMessage(selected string) string {
	return "`" + strings.TrimSpace(selected) + "`\n"
}

func commitFromHistoryFzfArgs() []string {
	height := os.Getenv("FZF_TMUX_HEIGHT")
	if height == "" {
		height = "40%"
	}
	return []string{
		"--height=" + height,
		"-n2..,..",
		"--scheme=history",
	}
}

func commitWithBacktickMessage(workDir, selected string, stdout, stderr io.Writer) error {
	msg := formatBacktickCommitMessage(selected)
	// Pass the message over stdin so shell special characters are never expanded.
	cmd := gitcmd.New(workDir, stdout, stderr).Command("commit", "--all", "--file=-")
	cmd.Stdin = strings.NewReader(msg)
	cmd.Stdout = stdout
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("git commit failed: %w", err)
	}
	return nil
}

func runCommitFromHistory(args []string, workDir string, stdin io.Reader, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("git-x commit-from-history", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git x commit-from-history\n\n")
		fmt.Fprintf(stderr, "Commit all changes using a shell history entry selected via fzf.\n")
	}

	if err := fs.Parse(args); err != nil {
		return err
	}
	if len(fs.Args()) != 0 {
		fs.Usage()
		return fmt.Errorf("expected no positional arguments, got %d", len(fs.Args()))
	}

	history := trimHistoryLines(stdin)
	if history == "" {
		return nil
	}

	var fzfOut bytes.Buffer
	fzfCmd := exec.Command("fzf", commitFromHistoryFzfArgs()...)
	fzfCmd.Stdin = strings.NewReader(history)
	fzfCmd.Stdout = &fzfOut
	fzfCmd.Stderr = stderr
	if err := fzfCmd.Run(); err != nil {
		if isCancelExitError(err) {
			return nil
		}
		return fmt.Errorf("fzf failed: %w", err)
	}

	selected := strings.TrimSpace(fzfOut.String())
	if selected == "" {
		return nil
	}

	return commitWithBacktickMessage(workDir, selected, stdout, stderr)
}
