package main

import (
	"encoding/json"
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

func isDir(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.IsDir()
}

func isRegularOrSymlinkNonDir(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}

func hasOriginRemote(r *gitRunner) bool {
	out, err := r.output("remote")
	if err != nil {
		return false
	}
	return slices.Contains(strings.Fields(out), "origin")
}

func hasBranchOrRemote(r *gitRunner, branch string) bool {
	return r.ok("show-ref", "--verify", "--quiet", "refs/heads/"+branch) ||
		r.ok("show-ref", "--verify", "--quiet", "refs/remotes/origin/"+branch) ||
		r.ok("show-ref", "--verify", "--quiet", "refs/remotes/upstream/"+branch)
}

func detectDefaultBranch(r *gitRunner, currentBranch string) string {
	for _, remote := range []string{"origin", "upstream"} {
		if ref, err := r.output("symbolic-ref", "--short", "refs/remotes/"+remote+"/HEAD"); err == nil && ref != "" {
			candidate := strings.TrimPrefix(ref, remote+"/")
			if hasBranchOrRemote(r, candidate) {
				return candidate
			}
		}
	}

	for _, candidate := range []string{"main", "master", "trunk", "develop", "development"} {
		if hasBranchOrRemote(r, candidate) {
			return candidate
		}
	}

	return currentBranch
}

func isDirenvAllowed(dir string) bool {
	cmd := exec.Command("direnv", "status", "--json")
	cmd.Dir = dir
	out, err := cmd.Output()
	if err != nil {
		return false
	}
	var parsed struct {
		State struct {
			FoundRC *struct {
				Allowed int `json:"allowed"`
			} `json:"foundRC"`
		} `json:"state"`
	}
	if err := json.Unmarshal(out, &parsed); err != nil {
		return false
	}
	return parsed.State.FoundRC != nil && parsed.State.FoundRC.Allowed == 0
}

func allowDirenvIfTrusted(targetDir string, trusted bool, stderr io.Writer) error {
	if !trusted {
		return nil
	}
	if !isRegularOrSymlinkNonDir(filepath.Join(targetDir, ".envrc")) {
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

func resolveTargetRepoDir(args []string, workDir string, stderr io.Writer) (string, error) {
	if len(args) == 1 {
		abs, err := filepath.Abs(args[0])
		if err != nil {
			return "", fmt.Errorf("resolve repository path: %w", err)
		}
		return abs, nil
	}

	cwd := workDir
	if cwd == "" {
		var err error
		cwd, err = os.Getwd()
		if err != nil {
			return "", fmt.Errorf("resolve working directory: %w", err)
		}
	}

	r := &gitRunner{dir: cwd, stderr: stderr}
	if topLevel, err := r.output("rev-parse", "--path-format=absolute", "--show-toplevel"); err == nil && topLevel != "" {
		return filepath.Clean(topLevel), nil
	}

	// Allow running without arguments from an already-migrated clean-bare container directory.
	if isDir(filepath.Join(cwd, ".git")) {
		return filepath.Clean(cwd), nil
	}

	return "", errors.New("not inside a git repository")
}

func checkNoInProgressOperation(gitDir string) error {
	stateEntries := []string{
		"MERGE_HEAD",
		"CHERRY_PICK_HEAD",
		"REVERT_HEAD",
		"BISECT_LOG",
		"rebase-merge",
		"rebase-apply",
	}
	for _, name := range stateEntries {
		if _, err := os.Lstat(filepath.Join(gitDir, name)); err == nil {
			return fmt.Errorf("in-progress git operation detected (%s); finish or abort it before migrating", name)
		}
	}
	return nil
}

func rollbackMoves(repoDir, tmpWT string, moved []string) {
	for i := len(moved) - 1; i >= 0; i-- {
		name := moved[i]
		_ = os.Rename(filepath.Join(tmpWT, name), filepath.Join(repoDir, name))
	}
	_ = os.Remove(tmpWT)
}

func migrateRepo(repoDir string, dryRun, trust bool, stdout, stderr io.Writer) error {
	gitDir := filepath.Join(repoDir, ".git")
	info, err := os.Lstat(gitDir)
	if err != nil {
		return fmt.Errorf("%s is missing .git directory: %w", repoDir, err)
	}
	if !info.IsDir() {
		return fmt.Errorf("%s/.git is not a directory (linked worktree or submodule); pass the main repository root", repoDir)
	}

	r := &gitRunner{dir: repoDir, stderr: stderr}
	isBare, err := r.output("rev-parse", "--is-bare-repository")
	if err != nil {
		return err
	}
	if isBare == "true" {
		fmt.Fprintf(stderr, "Repository is already bare: %s\n", repoDir)
		return nil
	}

	if wtConfig, err := r.output("config", "--get", "core.worktree"); err == nil && wtConfig != "" {
		return fmt.Errorf("core.worktree is set (%s); refusing to migrate non-standard repository layout", wtConfig)
	}

	if err := checkNoInProgressOperation(gitDir); err != nil {
		return err
	}

	branch, err := r.output("symbolic-ref", "--short", "HEAD")
	if err != nil || branch == "" {
		return errors.New("repository is in detached HEAD state; switch to a branch before migrating")
	}

	// Replace "/" so all worktrees stay flat at depth 1 under the repository directory.
	branchDir := strings.ReplaceAll(branch, "/", "-")
	if branchDir == "" || branchDir == "." || branchDir == ".." || branchDir == ".git" {
		return fmt.Errorf("invalid target worktree directory name %q for branch %q", branchDir, branch)
	}
	targetDir := filepath.Join(repoDir, branchDir)

	wasTrusted := isDirenvAllowed(repoDir)
	shouldTrust := trust || wasTrusted
	defaultBranch := detectDefaultBranch(r, branch)

	if dryRun {
		fmt.Fprintf(stdout, "[dry-run] convert %s to clean-bare with worktree %s (branch %s)\n", repoDir, targetDir, branch)
		if shouldTrust && isRegularOrSymlinkNonDir(filepath.Join(repoDir, ".envrc")) {
			fmt.Fprintf(stdout, "[dry-run] direnv allow %s\n", targetDir)
		}
		return nil
	}

	entries, err := os.ReadDir(repoDir)
	if err != nil {
		return fmt.Errorf("read repository directory: %w", err)
	}

	tmpWT, err := os.MkdirTemp(repoDir, ".git-migrate-tmp-*")
	if err != nil {
		return fmt.Errorf("create temporary directory: %w", err)
	}
	if err := os.Chmod(tmpWT, 0o755); err != nil {
		_ = os.Remove(tmpWT)
		return fmt.Errorf("set permissions on temporary directory: %w", err)
	}
	tmpBase := filepath.Base(tmpWT)

	var moved []string
	for _, entry := range entries {
		name := entry.Name()
		if name == ".git" || name == tmpBase {
			continue
		}
		if err := os.Rename(filepath.Join(repoDir, name), filepath.Join(tmpWT, name)); err != nil {
			rollbackMoves(repoDir, tmpWT, moved)
			return fmt.Errorf("move %s into temporary worktree: %w", name, err)
		}
		moved = append(moved, name)
	}

	if err := r.stream("config", "set", "core.bare", "true"); err != nil {
		rollbackMoves(repoDir, tmpWT, moved)
		return err
	}

	if hasOriginRemote(r) {
		if err := r.stream("config", "set", "remote.origin.fetch", "+refs/heads/*:refs/remotes/origin/*"); err != nil {
			_ = r.ok("config", "set", "core.bare", "false")
			rollbackMoves(repoDir, tmpWT, moved)
			return err
		}
	}

	hasBranch := r.ok("show-ref", "--verify", "--quiet", "refs/heads/"+branch)
	var worktreeErr error
	if hasBranch {
		worktreeErr = r.stream("worktree", "add", "--no-checkout", targetDir, branch)
	} else {
		worktreeErr = r.stream("worktree", "add", "--orphan", "-b", branch, targetDir)
	}
	if worktreeErr != nil {
		_ = os.RemoveAll(targetDir)
		_ = r.ok("config", "set", "core.bare", "false")
		rollbackMoves(repoDir, tmpWT, moved)
		return worktreeErr
	}

	if err := os.Rename(filepath.Join(targetDir, ".git"), filepath.Join(tmpWT, ".git")); err != nil {
		return fmt.Errorf("move worktree .git pointer into %s: %w", tmpWT, err)
	}
	if err := os.Remove(targetDir); err != nil {
		return fmt.Errorf("remove temporary empty worktree directory %s: %w", targetDir, err)
	}

	// Clear stale .direnv cache whose paths pointed at the pre-migration root.
	if err := os.RemoveAll(filepath.Join(tmpWT, ".direnv")); err != nil {
		return fmt.Errorf("remove stale .direnv directory: %w", err)
	}

	if err := os.Rename(tmpWT, targetDir); err != nil {
		return fmt.Errorf("rename %s to %s: %w", tmpWT, targetDir, err)
	}

	wtRunner := &gitRunner{dir: targetDir, stderr: stderr}
	wtGitDir, err := wtRunner.output("rev-parse", "--path-format=absolute", "--git-dir")
	if err != nil {
		return err
	}

	srcIndex := filepath.Join(gitDir, "index")
	if _, err := os.Lstat(srcIndex); err == nil {
		if err := os.Rename(srcIndex, filepath.Join(wtGitDir, "index")); err != nil {
			return fmt.Errorf("move staging index to worktree git dir: %w", err)
		}
	}

	// Keep the bare repository HEAD aligned with the repository's default branch,
	// matching fresh `ghq get --clean-bare` clones so tools like ghqf detect it cleanly.
	if defaultBranch != "" && defaultBranch != branch && r.ok("show-ref", "--verify", "--quiet", "refs/heads/"+defaultBranch) {
		if err := r.stream("symbolic-ref", "HEAD", "refs/heads/"+defaultBranch); err != nil {
			return err
		}
	}

	if err := r.stream("worktree", "repair"); err != nil {
		return err
	}

	if err := allowDirenvIfTrusted(targetDir, shouldTrust, stderr); err != nil {
		return err
	}

	fmt.Fprintln(stdout, targetDir)
	return nil
}

func run(args []string, workDir string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("git-migrate-clean-bare", flag.ContinueOnError)
	fs.SetOutput(stderr)
	dryRun := fs.Bool("dry-run", false, "show planned migration actions without changing the repository")
	trust := fs.Bool("trust", false, "run direnv allow if .envrc exists in the migrated worktree")

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git-migrate-clean-bare [--dry-run] [--trust] [<repo_dir>]\n\n")
		fmt.Fprintf(stderr, "Convert a standard Git repository into the clean-bare worktree layout in place.\n\n")
		fs.PrintDefaults()
	}

	if err := fs.Parse(args); err != nil {
		return err
	}

	remaining := fs.Args()
	if len(remaining) > 1 {
		fs.Usage()
		return fmt.Errorf("expected at most 1 repository directory argument, got %d", len(remaining))
	}

	repoDir, err := resolveTargetRepoDir(remaining, workDir, stderr)
	if err != nil {
		return err
	}

	return migrateRepo(repoDir, *dryRun, *trust, stdout, stderr)
}

func main() {
	if err := run(os.Args[1:], "", os.Stdout, os.Stderr); err != nil {
		if !errors.Is(err, flag.ErrHelp) {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		}
		os.Exit(1)
	}
}
