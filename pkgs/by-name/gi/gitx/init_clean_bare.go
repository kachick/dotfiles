package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/kachick/dotfiles/internal/gitcmd"
)

func detectInitDefaultBranch(r *gitcmd.Runner) (string, error) {
	if ref, err := r.Output("symbolic-ref", "--short", "refs/remotes/origin/HEAD"); err == nil && ref != "" {
		return strings.TrimPrefix(ref, "origin/"), nil
	}
	if branch, err := r.Output("symbolic-ref", "--short", "HEAD"); err == nil && branch != "" {
		return branch, nil
	}
	return "", errors.New("cannot detect default branch")
}

func ensureDefaultWorktree(repoDir, defaultBranch string, stderr io.Writer) (string, error) {
	// Route git stdout to stderr so stdout only emits the resolved worktree path.
	r := gitcmd.NewIsolated(repoDir, stderr, stderr)

	if existing, err := gitcmd.FindBranchWorktree(r, defaultBranch); err != nil {
		return "", err
	} else if existing != "" {
		return existing, nil
	}

	// Replace "/" so all worktrees stay flat at depth 1 under the repository directory.
	dirName := strings.ReplaceAll(defaultBranch, "/", "-")
	targetDir := filepath.Join(repoDir, dirName)

	if _, err := os.Stat(targetDir); err == nil {
		return "", fmt.Errorf("target worktree path already exists and is not registered for %s: %s", defaultBranch, targetDir)
	} else if !os.IsNotExist(err) {
		return "", err
	}

	hasLocalBranch := r.Ok("show-ref", "--verify", "--quiet", "refs/heads/"+defaultBranch)
	hasOriginBranch := r.Ok("show-ref", "--verify", "--quiet", "refs/remotes/origin/"+defaultBranch)

	switch {
	case hasLocalBranch:
		if err := r.Stream("worktree", "add", targetDir, defaultBranch); err != nil {
			return "", err
		}
	case hasOriginBranch:
		if err := r.Stream("worktree", "add", "--track", "-b", defaultBranch, targetDir, "origin/"+defaultBranch); err != nil {
			return "", err
		}
	default:
		// Empty repositories (unborn HEAD) have no commit yet; create an orphan worktree instead of failing.
		if err := r.Stream("worktree", "add", "--orphan", "-b", defaultBranch, targetDir); err != nil {
			return "", err
		}
	}

	if hasOriginBranch {
		wtRunner := gitcmd.NewIsolated(targetDir, stderr, stderr)
		if err := wtRunner.Stream("branch", "--set-upstream-to=origin/"+defaultBranch, defaultBranch); err != nil {
			return "", err
		}
	}

	return targetDir, nil
}

func runInitCleanBare(args []string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("gitx init-clean-bare", flag.ContinueOnError)
	fs.SetOutput(stderr)
	trust := fs.Bool("trust", false, "run direnv allow if .envrc exists in the target worktree")

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: gitx init-clean-bare [--trust] <repo_dir>\n\n")
		fmt.Fprintf(stderr, "Initialize default branch worktree for a bare repository and print its path.\n\n")
		fs.PrintDefaults()
	}

	if err := fs.Parse(args); err != nil {
		return err
	}

	remaining := fs.Args()
	if len(remaining) != 1 {
		fs.Usage()
		return fmt.Errorf("expected 1 repository directory argument, got %d", len(remaining))
	}

	repoDir, err := filepath.Abs(remaining[0])
	if err != nil {
		return fmt.Errorf("resolve repository path: %w", err)
	}

	return initCleanBare(repoDir, *trust, stdout, stderr)
}

func initCleanBare(repoDir string, trust bool, stdout, stderr io.Writer) error {
	r := gitcmd.NewIsolated(repoDir, stderr, stderr)
	isBare, err := r.Output("rev-parse", "--is-bare-repository")
	if err != nil {
		return err
	}

	// Legacy non-bare repositories do not need worktree initialization; return repoDir directly.
	if isBare != "true" {
		if err := allowDirenvIfTrusted(repoDir, trust, stderr); err != nil {
			return err
		}
		fmt.Fprintln(stdout, repoDir)
		return nil
	}

	if hasOriginRemote(r) {
		if err := r.Stream("config", "set", "remote.origin.fetch", "+refs/heads/*:refs/remotes/origin/*"); err != nil {
			return err
		}
		if err := r.Stream("fetch", "--quiet", "origin"); err != nil {
			return err
		}
		// Ignore errors when remote HEAD is unset (for example, empty repositories).
		_ = r.Ok("remote", "set-head", "origin", "--auto")
	}

	defaultBranch, err := detectInitDefaultBranch(r)
	if err != nil {
		return err
	}

	targetDir, err := ensureDefaultWorktree(repoDir, defaultBranch, stderr)
	if err != nil {
		return err
	}

	if err := allowDirenvIfTrusted(targetDir, trust, stderr); err != nil {
		return err
	}

	fmt.Fprintln(stdout, targetDir)
	return nil
}
