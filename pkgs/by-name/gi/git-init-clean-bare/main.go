package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
)

type gitRunner struct {
	dir    string
	stderr io.Writer
}

func (r *gitRunner) output(args ...string) (string, error) {
	cmd := exec.Command("git", args...)
	if r.dir != "" {
		cmd.Dir = r.dir
	}
	out, err := cmd.CombinedOutput()
	trimmed := strings.TrimSpace(string(out))
	if err != nil {
		return trimmed, fmt.Errorf("git %s: %w: %s", strings.Join(args, " "), err, trimmed)
	}
	return trimmed, nil
}

func (r *gitRunner) ok(args ...string) bool {
	cmd := exec.Command("git", args...)
	if r.dir != "" {
		cmd.Dir = r.dir
	}
	return cmd.Run() == nil
}

func (r *gitRunner) stream(args ...string) error {
	cmd := exec.Command("git", args...)
	if r.dir != "" {
		cmd.Dir = r.dir
	}
	// Send git progress to stderr so stdout only prints the resolved worktree path.
	cmd.Stdout = r.stderr
	cmd.Stderr = r.stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("git %s: %w", strings.Join(args, " "), err)
	}
	return nil
}

func hasOriginRemote(r *gitRunner) bool {
	out, err := r.output("remote")
	if err != nil {
		return false
	}
	return slices.Contains(strings.Fields(out), "origin")
}

func detectDefaultBranch(r *gitRunner) (string, error) {
	if ref, err := r.output("symbolic-ref", "--short", "refs/remotes/origin/HEAD"); err == nil && ref != "" {
		return strings.TrimPrefix(ref, "origin/"), nil
	}
	if branch, err := r.output("symbolic-ref", "--short", "HEAD"); err == nil && branch != "" {
		return branch, nil
	}
	return "", errors.New("cannot detect default branch")
}

// findBranchWorktree scans `git worktree list --porcelain` so re-running on an
// already-initialized repository returns the existing worktree path cleanly.
func findBranchWorktree(r *gitRunner, branch string) (string, error) {
	out, err := r.output("worktree", "list", "--porcelain")
	if err != nil {
		return "", err
	}

	targetRef := "refs/heads/" + branch
	var currentPath string
	for line := range strings.SplitSeq(out, "\n") {
		line = strings.TrimSpace(line)
		switch {
		case line == "":
			currentPath = ""
		case strings.HasPrefix(line, "worktree "):
			currentPath = strings.TrimPrefix(line, "worktree ")
		case line == "branch "+targetRef && currentPath != "":
			return currentPath, nil
		}
	}
	return "", nil
}

func allowDirenvIfTrusted(targetDir string, trust bool, stderr io.Writer) error {
	if !trust {
		return nil
	}
	envrcPath := filepath.Join(targetDir, ".envrc")
	info, err := os.Stat(envrcPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	if info.IsDir() {
		return nil
	}

	cmd := exec.Command("direnv", "allow", targetDir)
	cmd.Stdout = stderr
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("direnv allow %s: %w", targetDir, err)
	}
	return nil
}

func ensureDefaultWorktree(repoDir, defaultBranch string, stderr io.Writer) (string, error) {
	r := &gitRunner{dir: repoDir, stderr: stderr}

	if existing, err := findBranchWorktree(r, defaultBranch); err != nil {
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

	hasLocalBranch := r.ok("show-ref", "--verify", "--quiet", "refs/heads/"+defaultBranch)
	hasOriginBranch := r.ok("show-ref", "--verify", "--quiet", "refs/remotes/origin/"+defaultBranch)

	switch {
	case hasLocalBranch:
		if err := r.stream("worktree", "add", targetDir, defaultBranch); err != nil {
			return "", err
		}
	case hasOriginBranch:
		if err := r.stream("worktree", "add", "--track", "-b", defaultBranch, targetDir, "origin/"+defaultBranch); err != nil {
			return "", err
		}
	default:
		// Empty repositories (unborn HEAD) have no commit yet; create an orphan worktree instead of failing.
		if err := r.stream("worktree", "add", "--orphan", "-b", defaultBranch, targetDir); err != nil {
			return "", err
		}
	}

	if hasOriginBranch {
		wtRunner := &gitRunner{dir: targetDir, stderr: stderr}
		if err := wtRunner.stream("branch", "--set-upstream-to=origin/"+defaultBranch, defaultBranch); err != nil {
			return "", err
		}
	}

	return targetDir, nil
}

func run(args []string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("git-init-clean-bare", flag.ContinueOnError)
	fs.SetOutput(stderr)
	trust := fs.Bool("trust", false, "run direnv allow if .envrc exists in the target worktree")

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git-init-clean-bare [--trust] <repo_dir>\n\n")
		fmt.Fprintf(stderr, "Initialize default branch worktree for a ghq --clean-bare repository and print its path.\n\n")
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

	r := &gitRunner{dir: repoDir, stderr: stderr}
	isBare, err := r.output("rev-parse", "--is-bare-repository")
	if err != nil {
		return err
	}

	// Legacy non-bare repositories do not need worktree initialization; return repoDir directly.
	if isBare != "true" {
		if err := allowDirenvIfTrusted(repoDir, *trust, stderr); err != nil {
			return err
		}
		fmt.Fprintln(stdout, repoDir)
		return nil
	}

	if hasOriginRemote(r) {
		if err := r.stream("config", "set", "remote.origin.fetch", "+refs/heads/*:refs/remotes/origin/*"); err != nil {
			return err
		}
		if err := r.stream("fetch", "--quiet", "origin"); err != nil {
			return err
		}
		// Ignore errors when remote HEAD is unset (for example, empty repositories).
		_ = r.ok("remote", "set-head", "origin", "--auto")
	}

	defaultBranch, err := detectDefaultBranch(r)
	if err != nil {
		return err
	}

	targetDir, err := ensureDefaultWorktree(repoDir, defaultBranch, stderr)
	if err != nil {
		return err
	}

	if err := allowDirenvIfTrusted(targetDir, *trust, stderr); err != nil {
		return err
	}

	fmt.Fprintln(stdout, targetDir)
	return nil
}

func main() {
	if err := run(os.Args[1:], os.Stdout, os.Stderr); err != nil {
		if !errors.Is(err, flag.ErrHelp) {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		}
		os.Exit(1)
	}
}
