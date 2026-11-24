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
	"strings"

	"github.com/kachick/dotfiles/internal/gitcmd"
)

type ghPRInfo struct {
	Number            int    `json:"number"`
	HeadRefName       string `json:"headRefName"`
	IsCrossRepository bool   `json:"isCrossRepository"`
}

type wtPRDeps struct {
	viewPR     func(workDir, prRef, repo string, stderr io.Writer) (ghPRInfo, error)
	checkoutPR func(workDir, prRef, repo, branch string, stderr io.Writer) error
}

func (d wtPRDeps) withDefaults() wtPRDeps {
	if d.viewPR == nil {
		d.viewPR = runGHPRView
	}
	if d.checkoutPR == nil {
		d.checkoutPR = runGHPRCheckout
	}
	return d
}

func runGHPRView(workDir, prRef, repo string, stderr io.Writer) (ghPRInfo, error) {
	args := []string{"pr", "view", prRef, "--json", "number,headRefName,isCrossRepository"}
	if repo != "" {
		args = append(args, "--repo", repo)
	}
	cmd := exec.Command("gh", args...)
	if workDir != "" {
		cmd.Dir = workDir
		// Clear repo-binding Git env vars (e.g. from `git wt` alias) so gh operates strictly in workDir.
		cmd.Env = gitcmd.IsolatedEnv(os.Environ())
	}
	var out bytes.Buffer
	var errBuf bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &errBuf
	if err := cmd.Run(); err != nil {
		detail := strings.TrimSpace(errBuf.String())
		if detail != "" {
			fmt.Fprintln(stderr, detail)
		}
		return ghPRInfo{}, fmt.Errorf("gh pr view %s: %w", prRef, err)
	}

	var info ghPRInfo
	if err := json.Unmarshal(out.Bytes(), &info); err != nil {
		return ghPRInfo{}, fmt.Errorf("parse gh pr view output: %w", err)
	}
	if info.HeadRefName == "" {
		return ghPRInfo{}, fmt.Errorf("gh pr view %s returned empty headRefName", prRef)
	}
	return info, nil
}

func runGHPRCheckout(workDir, prRef, repo, branch string, stderr io.Writer) error {
	args := []string{"pr", "checkout", prRef}
	if repo != "" {
		args = append(args, "--repo", repo)
	}
	if branch != "" {
		args = append(args, "--branch", branch)
	}
	cmd := exec.Command("gh", args...)
	if workDir != "" {
		cmd.Dir = workDir
		// Clear repo-binding Git env vars (e.g. from `git wt` alias) so gh operates strictly in workDir.
		cmd.Env = gitcmd.IsolatedEnv(os.Environ())
	}
	// Route gh stdout to stderr so shell wrappers like `cd "$(gitx wt pr ...)"` only receive the worktree path.
	cmd.Stdout = stderr
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("gh pr checkout %s: %w", prRef, err)
	}
	return nil
}

func resolveDetachBaseRef(r *gitcmd.Runner, defaultBranch string) (string, error) {
	for _, ref := range []string{
		"refs/heads/" + defaultBranch,
		"refs/remotes/origin/" + defaultBranch,
		"HEAD",
	} {
		if defaultBranch == "" && strings.HasSuffix(ref, "/") {
			continue
		}
		if r.Ok("rev-parse", "--verify", "--quiet", ref+"^{commit}") {
			return ref, nil
		}
	}
	return "", errors.New("repository has no commits to create a worktree from")
}

func newWTPRFlagSet(stderr io.Writer) (*flag.FlagSet, *string, *bool) {
	fs := flag.NewFlagSet("gitx wt pr", flag.ContinueOnError)
	fs.SetOutput(stderr)
	repo := fs.String("repo", "", "target repository in OWNER/REPO format (passed to gh --repo)")
	trust := fs.Bool("trust", false, "run direnv allow if .envrc exists in the target worktree")

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: gitx wt pr [--repo <OWNER/REPO>] [--trust] <number|url|branch>\n\n")
		fmt.Fprintf(stderr, "Check out a GitHub pull request into a flat worktree without switching the current worktree.\n")
		fmt.Fprintf(stderr, "Falls back to `gh pr checkout` in non-clean-bare repositories.\n\n")
		fs.PrintDefaults()
	}
	return fs, repo, trust
}

func wtRunPRWithDeps(args []string, workDir string, deps wtPRDeps, stdout, stderr io.Writer) error {
	deps = deps.withDefaults()
	fs, repo, trust := newWTPRFlagSet(stderr)
	if err := fs.Parse(args); err != nil {
		return err
	}
	remaining := fs.Args()
	if len(remaining) != 1 {
		fs.Usage()
		return fmt.Errorf("expected 1 pull request argument, got %d", len(remaining))
	}

	prRef := strings.TrimPrefix(strings.TrimSpace(remaining[0]), "#")
	if prRef == "" || strings.HasPrefix(prRef, "-") {
		return fmt.Errorf("invalid pull request reference: %q", remaining[0])
	}

	ctx, err := gitcmd.DetectRepoContext(workDir, stderr, stderr)
	if err != nil {
		return err
	}

	// Non-clean-bare repositories do not use flat worktrees; delegate directly to `gh pr checkout`.
	if !ctx.IsBare || filepath.Base(ctx.CommonDir) != ".git" {
		return deps.checkoutPR(workDir, prRef, *repo, "", stderr)
	}

	prInfo, err := deps.viewPR(workDir, prRef, *repo, stderr)
	if err != nil {
		return err
	}

	r := gitcmd.NewIsolated(ctx.ContainerDir, stderr, stderr)
	defaultBranch, _ := gitcmd.DetectDefaultBranch(r, ctx.CommonDir, ctx.IsBare)

	localBranch := prInfo.HeadRefName
	explicitBranch := ""
	if prInfo.IsCrossRepository && defaultBranch != "" && localBranch == defaultBranch && prInfo.Number > 0 {
		// Avoid colliding with the repository's default branch when a fork PR targets from its own default branch.
		localBranch = fmt.Sprintf("pr-%d", prInfo.Number)
		explicitBranch = localBranch
	}
	if strings.HasPrefix(localBranch, "-") || !r.Ok("check-ref-format", "--branch", localBranch) {
		return fmt.Errorf("invalid PR branch name: %q", localBranch)
	}

	existing, err := gitcmd.ListWorktrees(r)
	if err != nil {
		return err
	}
	for _, wt := range existing {
		if wt.Branch != localBranch {
			continue
		}
		if gitcmd.IsCleanBareDefaultWorktree(ctx, defaultBranch, wt.Path) {
			return fmt.Errorf("branch %q is currently checked out in default worktree %s; run `wt promote` first", localBranch, wt.Path)
		}
		if err := deps.checkoutPR(wt.Path, prRef, *repo, explicitBranch, stderr); err != nil {
			return err
		}
		if err := maybeAllowDirenv(wt.Path, existing, *trust, nil, stderr); err != nil {
			return err
		}
		fmt.Fprintln(stdout, wt.Path)
		return nil
	}

	dirName, err := gitcmd.WorktreeDirName(localBranch)
	if err != nil {
		return err
	}
	targetDir := filepath.Join(ctx.ContainerDir, dirName)
	if _, err := os.Stat(targetDir); err == nil {
		return fmt.Errorf("target worktree path already exists: %s", targetDir)
	} else if !os.IsNotExist(err) {
		return err
	}

	baseRef, err := resolveDetachBaseRef(r, defaultBranch)
	if err != nil {
		return err
	}
	if err := r.Stream("worktree", "add", "--detach", targetDir, baseRef); err != nil {
		return err
	}

	if err := deps.checkoutPR(targetDir, prRef, *repo, explicitBranch, stderr); err != nil {
		_ = r.Stream("worktree", "remove", "--force", targetDir)
		return err
	}

	if err := maybeAllowDirenv(targetDir, existing, *trust, nil, stderr); err != nil {
		return err
	}
	fmt.Fprintf(stderr, "Checked out PR #%d into worktree: %s (branch %s)\n", prInfo.Number, targetDir, localBranch)
	fmt.Fprintln(stdout, targetDir)
	return nil
}

func newWTPromoteFlagSet(stderr io.Writer) (*flag.FlagSet, *bool) {
	fs := flag.NewFlagSet("gitx wt promote", flag.ContinueOnError)
	fs.SetOutput(stderr)
	trust := fs.Bool("trust", false, "run direnv allow if .envrc exists in the target worktree")

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: gitx wt promote [--trust]\n\n")
		fmt.Fprintf(stderr, "Move the current checked-out branch into its own flat worktree and switch the current worktree back to the default branch.\n\n")
		fs.PrintDefaults()
	}
	return fs, trust
}

func wtRunPromote(args []string, workDir string, stdout, stderr io.Writer) error {
	fs, trust := newWTPromoteFlagSet(stderr)
	if err := fs.Parse(args); err != nil {
		return err
	}
	if len(fs.Args()) != 0 {
		fs.Usage()
		return fmt.Errorf("expected no arguments, got %d", len(fs.Args()))
	}

	ctx, err := gitcmd.DetectRepoContext(workDir, stderr, stderr)
	if err != nil {
		return err
	}
	if !ctx.IsBare || filepath.Base(ctx.CommonDir) != ".git" {
		return errors.New("repository does not use clean-bare layout (<repo>/.git); cannot promote branch to a flat worktree")
	}

	cwdRunner := gitcmd.New(workDir, stderr, stderr)
	topLevel, err := cwdRunner.Output("rev-parse", "--path-format=absolute", "--show-toplevel")
	if err != nil || topLevel == "" {
		return errors.New("must be run inside a worktree")
	}
	topLevel = filepath.Clean(topLevel)

	curRunner := gitcmd.NewIsolated(topLevel, stderr, stderr)
	curBranch, err := curRunner.Output("symbolic-ref", "--short", "HEAD")
	if err != nil || curBranch == "" {
		return errors.New("HEAD is detached; switch to a branch before promoting")
	}

	r := gitcmd.NewIsolated(ctx.ContainerDir, stderr, stderr)
	defaultBranch, err := gitcmd.DetectDefaultBranch(r, ctx.CommonDir, ctx.IsBare)
	if err != nil {
		return err
	}
	if curBranch == defaultBranch {
		return fmt.Errorf("already on default branch %q", defaultBranch)
	}

	dirName, err := gitcmd.WorktreeDirName(curBranch)
	if err != nil {
		return err
	}
	targetDir := filepath.Join(ctx.ContainerDir, dirName)

	existing, err := gitcmd.ListWorktrees(r)
	if err != nil {
		return err
	}
	if resolveRealPath(topLevel) == resolveRealPath(targetDir) {
		if err := maybeAllowDirenv(topLevel, existing, *trust, nil, stderr); err != nil {
			return err
		}
		fmt.Fprintln(stdout, topLevel)
		return nil
	}

	if _, err := os.Stat(targetDir); err == nil {
		return fmt.Errorf("target worktree path already exists: %s", targetDir)
	} else if !os.IsNotExist(err) {
		return err
	}

	status, err := curRunner.OutputRaw("status", "--porcelain")
	if err != nil {
		return err
	}
	if len(bytes.TrimSpace(status)) > 0 {
		return errors.New("working tree has uncommitted changes; commit or stash them first")
	}

	for _, wt := range existing {
		if wt.Branch == defaultBranch {
			return fmt.Errorf("default branch %q is already checked out at %s; cannot switch current worktree away from %q", defaultBranch, wt.Path, curBranch)
		}
	}

	hasLocalDefault := r.Ok("show-ref", "--verify", "--quiet", "refs/heads/"+defaultBranch)
	hasOriginDefault := r.Ok("show-ref", "--verify", "--quiet", "refs/remotes/origin/"+defaultBranch)
	switch {
	case hasLocalDefault:
		if err := curRunner.Stream("switch", defaultBranch); err != nil {
			return err
		}
	case hasOriginDefault:
		if err := curRunner.Stream("switch", "--track", "-c", defaultBranch, "origin/"+defaultBranch); err != nil {
			return err
		}
	default:
		return fmt.Errorf("default branch %q does not exist locally or on origin", defaultBranch)
	}

	if err := r.Stream("worktree", "add", targetDir, curBranch); err != nil {
		// Best-effort rollback so the user stays on the original branch if worktree creation fails.
		_ = curRunner.Stream("switch", curBranch)
		return err
	}

	if err := maybeAllowDirenv(targetDir, existing, *trust, nil, stderr); err != nil {
		return err
	}
	fmt.Fprintf(stderr, "Promoted branch %s to worktree: %s\n", curBranch, targetDir)
	fmt.Fprintln(stdout, targetDir)
	return nil
}
