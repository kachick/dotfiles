package main

import (
	"bytes"
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

	"github.com/kachick/dotfiles/internal/gitcmd"
)

type migrateOptions struct {
	dryRun      bool
	trust       bool
	interactive bool
	selector    branchSelector
}

type branchSelector func(repoDir, currentBranch, defaultBranch string, candidates []gitcmd.BranchCandidate, stderr io.Writer) ([]string, error)

func isDir(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.IsDir()
}

func isRegularOrSymlinkNonDir(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}

func hasOriginRemote(r *gitcmd.Runner) bool {
	out, err := r.Output("remote")
	if err != nil {
		return false
	}
	return slices.Contains(strings.Fields(out), "origin")
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

func allowDirenv(targetDir string, stderr io.Writer) error {
	cmd := exec.Command("direnv", "allow", targetDir)
	cmd.Stdout = stderr
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("direnv allow %s: %w", targetDir, err)
	}
	return nil
}

func allowDirenvIfTrusted(targetDir string, trusted bool, stderr io.Writer) error {
	if !trusted || !isRegularOrSymlinkNonDir(filepath.Join(targetDir, ".envrc")) {
		return nil
	}
	return allowDirenv(targetDir, stderr)
}

func maybeAllowExtraWorktreeDirenv(targetDir, currentWT string, wasTrusted, trust bool, stderr io.Writer) error {
	envrcPath := filepath.Join(targetDir, ".envrc")
	if !isRegularOrSymlinkNonDir(envrcPath) {
		return nil
	}
	if trust {
		return allowDirenv(targetDir, stderr)
	}
	if !wasTrusted {
		return nil
	}

	targetBytes, err := os.ReadFile(envrcPath)
	if err != nil {
		return err
	}
	currentBytes, err := os.ReadFile(filepath.Join(currentWT, ".envrc"))
	if err != nil || !bytes.Equal(targetBytes, currentBytes) {
		return nil
	}
	// Only auto-allow when the extra worktree's .envrc matches the already-trusted current worktree.
	return allowDirenv(targetDir, stderr)
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

	r := gitcmd.New(cwd, stderr, stderr)
	if topLevel, err := r.Output("rev-parse", "--path-format=absolute", "--show-toplevel"); err == nil && topLevel != "" {
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

func fzfInteractiveArgs(selfExe, repoDir, defaultBranch, currentBranch string, initialSelectCount int) []string {
	return gitcmd.FzfBranchSelectArgs(gitcmd.FzfBranchSelectOptions{
		SelfExe:            selfExe,
		RepoDir:            repoDir,
		DefaultBranch:      defaultBranch,
		PreviewSubcommand:  "_preview",
		BorderLabel:        "🌴 Migrate Branches",
		Header:             fmt.Sprintf("TAB: toggle | ENTER: migrate | ESC: cancel (current %q is always kept)", currentBranch),
		InitialSelectCount: initialSelectCount,
	})
}

func selectBranchesWithFzf(repoDir, currentBranch, defaultBranch string, candidates []gitcmd.BranchCandidate, stderr io.Writer) ([]string, error) {
	picked, err := gitcmd.SelectBranchesWithFzf(gitcmd.FzfBranchSelectOptions{
		RepoDir:            repoDir,
		DefaultBranch:      defaultBranch,
		PreviewSubcommand:  "_preview",
		BorderLabel:        "🌴 Migrate Branches",
		Header:             fmt.Sprintf("TAB: toggle | ENTER: migrate | ESC: cancel (current %q is always kept)", currentBranch),
		InitialSelectCount: gitcmd.CountInitialSelections(candidates),
	}, candidates, stderr)
	if err != nil {
		if errors.Is(err, gitcmd.ErrSelectionCanceled) {
			return nil, errors.New("migration canceled")
		}
		return nil, err
	}
	return normalizeSelectedBranches(currentBranch, picked), nil
}

func normalizeSelectedBranches(currentBranch string, picked []string) []string {
	seen := map[string]bool{currentBranch: true}
	result := []string{currentBranch}
	for _, raw := range picked {
		branch := strings.TrimSpace(raw)
		if branch == "" || seen[branch] {
			continue
		}
		seen[branch] = true
		result = append(result, branch)
	}
	return result
}

func runPreview(args []string, stdout, stderr io.Writer) error {
	if len(args) < 3 {
		return nil
	}
	return gitcmd.RenderBranchPreview(args[0], args[1], args[2], stdout, stderr)
}

func migrateRepo(repoDir string, opts migrateOptions, stdout, stderr io.Writer) error {
	gitDir := filepath.Join(repoDir, ".git")
	info, err := os.Lstat(gitDir)
	if err != nil {
		return fmt.Errorf("%s is missing .git directory: %w", repoDir, err)
	}
	if !info.IsDir() {
		return fmt.Errorf("%s/.git is not a directory (linked worktree or submodule); pass the main repository root", repoDir)
	}

	r := gitcmd.NewIsolated(repoDir, stderr, stderr)
	isBare, err := r.Output("rev-parse", "--is-bare-repository")
	if err != nil {
		return err
	}
	if isBare == "true" {
		fmt.Fprintf(stderr, "Repository is already bare: %s\n", repoDir)
		return nil
	}

	if wtConfig, err := r.Output("config", "--get", "core.worktree"); err == nil && wtConfig != "" {
		return fmt.Errorf("core.worktree is set (%s); refusing to migrate non-standard repository layout", wtConfig)
	}

	if err := checkNoInProgressOperation(gitDir); err != nil {
		return err
	}

	branch, err := r.Output("symbolic-ref", "--short", "HEAD")
	if err != nil || branch == "" {
		return errors.New("repository is in detached HEAD state; switch to a branch before migrating")
	}

	wasTrusted := isDirenvAllowed(repoDir)
	shouldTrust := opts.trust || wasTrusted
	defaultBranch, err := gitcmd.DetectDefaultBranch(r, gitDir, false)
	if err != nil {
		defaultBranch = branch
	}

	selectedBranches := []string{branch}
	if opts.interactive {
		candidates, err := gitcmd.CollectLocalBranchCandidates(r, gitcmd.CandidateOptions{
			CurrentBranch:        branch,
			DefaultBranch:        defaultBranch,
			AllowCheckedOutDir:   repoDir,
			IncludeUnbornCurrent: true,
		})
		if err != nil {
			return err
		}
		selector := opts.selector
		if selector == nil {
			selector = selectBranchesWithFzf
		}
		picked, err := selector(repoDir, branch, defaultBranch, candidates, stderr)
		if err != nil {
			return err
		}
		selectedBranches = normalizeSelectedBranches(branch, picked)
	}

	targetDirs, err := gitcmd.ValidateTargetWorktreeDirs(repoDir, selectedBranches)
	if err != nil {
		return err
	}
	targetDir := targetDirs[branch]
	extraBranches := selectedBranches[1:]

	for _, extra := range extraBranches {
		if !r.Ok("show-ref", "--verify", "--quiet", "refs/heads/"+extra) {
			return fmt.Errorf("selected branch %q does not exist locally", extra)
		}
	}

	if opts.dryRun {
		fmt.Fprintf(stdout, "[dry-run] convert %s to clean-bare with worktree %s (branch %s)\n", repoDir, targetDir, branch)
		for _, extra := range extraBranches {
			fmt.Fprintf(stdout, "[dry-run] add worktree %s (branch %s)\n", targetDirs[extra], extra)
		}
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

	if err := r.Stream("config", "set", "core.bare", "true"); err != nil {
		rollbackMoves(repoDir, tmpWT, moved)
		return err
	}

	if hasOriginRemote(r) {
		if err := r.Stream("config", "set", "remote.origin.fetch", "+refs/heads/*:refs/remotes/origin/*"); err != nil {
			_ = r.Ok("config", "set", "core.bare", "false")
			rollbackMoves(repoDir, tmpWT, moved)
			return err
		}
	}

	hasBranch := r.Ok("show-ref", "--verify", "--quiet", "refs/heads/"+branch)
	var worktreeErr error
	if hasBranch {
		worktreeErr = r.Stream("worktree", "add", "--no-checkout", targetDir, branch)
	} else {
		worktreeErr = r.Stream("worktree", "add", "--orphan", "-b", branch, targetDir)
	}
	if worktreeErr != nil {
		_ = os.RemoveAll(targetDir)
		_ = r.Ok("config", "set", "core.bare", "false")
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

	wtRunner := gitcmd.NewIsolated(targetDir, stderr, stderr)
	wtGitDir, err := wtRunner.Output("rev-parse", "--path-format=absolute", "--git-dir")
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
	if defaultBranch != "" && defaultBranch != branch && r.Ok("show-ref", "--verify", "--quiet", "refs/heads/"+defaultBranch) {
		if err := r.Stream("symbolic-ref", "HEAD", "refs/heads/"+defaultBranch); err != nil {
			return err
		}
	}

	for _, extra := range extraBranches {
		extraDir := targetDirs[extra]
		if err := r.Stream("worktree", "add", extraDir, extra); err != nil {
			return err
		}
	}

	if err := r.Stream("worktree", "repair"); err != nil {
		return err
	}

	if err := allowDirenvIfTrusted(targetDir, shouldTrust, stderr); err != nil {
		return err
	}
	for _, extra := range extraBranches {
		extraDir := targetDirs[extra]
		if err := maybeAllowExtraWorktreeDirenv(extraDir, targetDir, wasTrusted, opts.trust, stderr); err != nil {
			return err
		}
		fmt.Fprintf(stderr, "Added worktree: %s (branch %s)\n", extraDir, extra)
	}

	fmt.Fprintln(stdout, targetDir)
	return nil
}

func runWithOptions(args []string, workDir string, selector branchSelector, stdout, stderr io.Writer) error {
	if len(args) > 0 && args[0] == "_preview" {
		return runPreview(args[1:], stdout, stderr)
	}

	fs := flag.NewFlagSet("git-migrate-clean-bare", flag.ContinueOnError)
	fs.SetOutput(stderr)
	dryRun := fs.Bool("dry-run", false, "show planned migration actions without changing the repository")
	trust := fs.Bool("trust", false, "run direnv allow if .envrc exists in the migrated worktree")
	interactive := fs.Bool("interactive", false, "select branches to convert into worktrees via fzf")

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git-migrate-clean-bare [--dry-run] [--trust] [--interactive] [<repo_dir>]\n\n")
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

	return migrateRepo(repoDir, migrateOptions{
		dryRun:      *dryRun,
		trust:       *trust,
		interactive: *interactive,
		selector:    selector,
	}, stdout, stderr)
}

func run(args []string, workDir string, stdout, stderr io.Writer) error {
	return runWithOptions(args, workDir, nil, stdout, stderr)
}

func main() {
	if err := run(os.Args[1:], "", os.Stdout, os.Stderr); err != nil {
		if !errors.Is(err, flag.ErrHelp) {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		}
		os.Exit(1)
	}
}
