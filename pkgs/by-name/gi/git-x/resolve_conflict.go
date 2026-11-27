package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os/exec"
	"strings"

	"github.com/kachick/dotfiles/pkgs/by-name/gi/git-x/internal/gitcmd"
)

func runResolveConflict(args []string, workDir string, stdin io.Reader, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("git-x resolve-conflict", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git x resolve-conflict\n\n")
		fmt.Fprintf(stderr, "Open unresolved conflict markers in helix.\n")
	}

	if err := fs.Parse(args); err != nil {
		return err
	}
	if len(fs.Args()) != 0 {
		fs.Usage()
		return fmt.Errorf("expected no positional arguments, got %d", len(fs.Args()))
	}

	r := gitcmd.New(workDir, stdout, stderr)
	rawFiles, err := r.Output("diff", "--name-only", "--diff-filter=U")
	if err != nil {
		return err
	}
	var unmerged []string
	for line := range strings.SplitSeq(rawFiles, "\n") {
		trimmed := strings.TrimSpace(line)
		if trimmed != "" {
			unmerged = append(unmerged, trimmed)
		}
	}
	if len(unmerged) == 0 {
		return nil
	}

	rgArgs := append([]string{"--vimgrep", "--fixed-strings", "<<<<<< HEAD"}, unmerged...)
	rgCmd := exec.Command("rg", rgArgs...)
	if workDir != "" {
		rgCmd.Dir = workDir
	}
	rgOut, err := rgCmd.Output()
	if err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) && exitErr.ExitCode() == 1 {
			return nil
		}
		return fmt.Errorf("rg failed: %w", err)
	}

	var locations []string
	for line := range strings.SplitSeq(string(rgOut), "\n") {
		if line == "" {
			continue
		}
		// Keep file:line:column from rg --vimgrep output.
		parts := strings.SplitN(line, ":", 4)
		if len(parts) < 3 {
			continue
		}
		locations = append(locations, strings.Join(parts[:3], ":"))
	}

	const maxHsplitsPerBatch = 3
	for i := 0; i < len(locations); i += maxHsplitsPerBatch {
		end := min(i+maxHsplitsPerBatch, len(locations))
		hxArgs := append([]string{"--hsplit"}, locations[i:end]...)
		hxCmd := exec.Command("hx", hxArgs...)
		if workDir != "" {
			hxCmd.Dir = workDir
		}
		hxCmd.Stdin = stdin
		hxCmd.Stdout = stdout
		hxCmd.Stderr = stderr
		if err := hxCmd.Run(); err != nil {
			if resetPath, lookErr := exec.LookPath("reset"); lookErr == nil {
				resetCmd := exec.Command(resetPath)
				resetCmd.Stdin = stdin
				resetCmd.Stdout = stdout
				resetCmd.Stderr = stderr
				_ = resetCmd.Run()
			}
			return fmt.Errorf("hx failed: %w", err)
		}
	}
	return nil
}
