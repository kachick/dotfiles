package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/kachick/dotfiles/pkgs/by-name/gi/git-x/internal/gitcmd"
)

type migrateOptions struct {
	dryRun      bool
	trust       bool
	interactive bool
	selector    migrateBranchSelector
}

type migrateBranchSelector func(repoDir, currentBranch, defaultBranch string, candidates []gitcmd.BranchCandidate, stderr io.Writer) ([]string, error)

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

func migrateFzfInteractiveArgs(selfExe, repoDir, defaultBranch, currentBranch string, initialSelectCount int) []string {
	return gitcmd.FzfBranchSelectArgs(gitcmd.FzfBranchSelectOptions{
		SelfExe:            selfExe,
		RepoDir:            repoDir,
		DefaultBranch:      defaultBranch,
		PreviewArgs:        []string{"migrate-clean-bare", "_preview"},
		BorderLabel:        "🌴 Migrate Branches",
		Header:             fmt.Sprintf("TAB: toggle | ENTER: migrate | ESC: cancel (current %q is always kept)", currentBranch),
		InitialSelectCount: initialSelectCount,
	})
}

func migrateSelectBranchesWithFzf(repoDir, currentBranch, defaultBranch string, candidates []gitcmd.BranchCandidate, stderr io.Writer) ([]string, error) {
	picked, err := gitcmd.SelectBranchesWithFzf(gitcmd.FzfBranchSelectOptions{
		RepoDir:            repoDir,
		DefaultBranch:      defaultBranch,
		PreviewArgs:        []string{"migrate-clean-bare", "_preview"},
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
	return migrateNormalizeSelectedBranches(currentBranch, picked), nil
}

func migrateNormalizeSelectedBranches(currentBranch string, picked []string) []string {
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

func migrateRunPreview(args []string, stdout, stderr io.Writer) error {
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
			selector = migrateSelectBranchesWithFzf
		}
		picked, err := selector(repoDir, branch, defaultBranch, candidates, stderr)
		if err != nil {
			return err
		}
		selectedBranches = migrateNormalizeSelectedBranches(branch, picked)
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
	// matching fresh `git-x get` clones so tools like `repo-fzf` detect it cleanly.
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

type migrateFlagValues struct {
	dryRun      *bool
	trust       *bool
	interactive *bool
}

func newMigrateCleanBareFlagSet(stderr io.Writer) (*flag.FlagSet, migrateFlagValues) {
	fs := flag.NewFlagSet("git-x migrate-clean-bare", flag.ContinueOnError)
	fs.SetOutput(stderr)
	vals := migrateFlagValues{
		dryRun:      fs.Bool("dry-run", false, "show planned migration actions without changing the repository"),
		trust:       fs.Bool("trust", false, "run direnv allow if .envrc exists in the migrated worktree"),
		interactive: fs.Bool("interactive", false, "select branches to convert into worktrees via fzf"),
	}

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git x migrate-clean-bare [--dry-run] [--trust] [--interactive] [<repo_dir>]\n\n")
		fmt.Fprintf(stderr, "Convert a standard Git repository into the clean-bare worktree layout in place.\n\n")
		fs.PrintDefaults()
	}
	return fs, vals
}

func runMigrateCleanBareWithOptions(args []string, workDir string, selector migrateBranchSelector, stdout, stderr io.Writer) error {
	if len(args) > 0 && args[0] == "_preview" {
		return migrateRunPreview(args[1:], stdout, stderr)
	}

	fs, vals := newMigrateCleanBareFlagSet(stderr)

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
		dryRun:      *vals.dryRun,
		trust:       *vals.trust,
		interactive: *vals.interactive,
		selector:    selector,
	}, stdout, stderr)
}

func runMigrateCleanBare(args []string, workDir string, stdout, stderr io.Writer) error {
	return runMigrateCleanBareWithOptions(args, workDir, nil, stdout, stderr)
}
