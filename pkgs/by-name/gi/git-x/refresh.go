package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"slices"
	"strings"

	"github.com/kachick/dotfiles/internal/gitcmd"
)

func detectUpstreamRemote(r *gitcmd.Runner) (string, error) {
	out, err := r.Output("remote")
	if err != nil {
		return "", err
	}
	remotes := strings.Fields(out)
	if slices.Contains(remotes, "upstream") {
		return "upstream", nil
	}
	if slices.Contains(remotes, "origin") {
		return "origin", nil
	}
	return "", errors.New("no upstream or origin remote found")
}

func runRefresh(args []string, workDir string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("git-x refresh", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git x refresh\n\n")
		fmt.Fprintf(stderr, "Update remotes and fast-forward the default branch across standard and clean-bare worktree layouts.\n")
	}

	if err := fs.Parse(args); err != nil {
		return err
	}
	if len(fs.Args()) != 0 {
		fs.Usage()
		return fmt.Errorf("expected no positional arguments, got %d", len(fs.Args()))
	}

	ctx, err := gitcmd.DetectRepoContext(workDir, stdout, stderr)
	if err != nil {
		return err
	}

	commonRunner := gitcmd.NewIsolated(ctx.CommonDir, stdout, stderr)
	remote, err := detectUpstreamRemote(commonRunner)
	if err != nil {
		return err
	}

	if err := commonRunner.Stream("remote", "update", remote, "--prune"); err != nil {
		return err
	}

	defaultBranch, err := gitcmd.DetectDefaultBranch(commonRunner, ctx.CommonDir, ctx.IsBare)
	if err != nil {
		return err
	}

	defaultWT, err := gitcmd.FindBranchWorktree(commonRunner, defaultBranch)
	if err != nil {
		return err
	}
	if defaultWT != "" {
		wtRunner := gitcmd.NewIsolated(defaultWT, stdout, stderr)
		return wtRunner.Stream("pull", "--ff-only", "--prune", remote, defaultBranch)
	}

	if ctx.IsBare {
		if defaultWTPath, ok := gitcmd.CleanBareDefaultWorktreePath(ctx, defaultBranch); ok && isDir(defaultWTPath) {
			fmt.Fprintf(stderr, "Warning: default worktree %s is not on %q; fetching %s directly without modifying it\n", defaultWTPath, defaultBranch, defaultBranch)
		}
		return commonRunner.Stream("fetch", "--prune", remote, defaultBranch+":"+defaultBranch)
	}

	topLevel, err := gitcmd.New(workDir, stdout, stderr).Output("rev-parse", "--path-format=absolute", "--show-toplevel")
	if err != nil || topLevel == "" {
		topLevel = ctx.ContainerDir
	}
	wtRunner := gitcmd.NewIsolated(topLevel, stdout, stderr)
	if err := wtRunner.Stream("switch", defaultBranch); err != nil {
		return err
	}
	return wtRunner.Stream("pull", "--ff-only", "--prune", remote, defaultBranch)
}
