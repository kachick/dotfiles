package main

import (
	"bytes"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/kachick/dotfiles/internal/gitcmd"
)

func resolveTargetRef(r *gitcmd.Runner, defaultBranch string) string {
	for _, ref := range []string{
		"refs/heads/" + defaultBranch,
		"refs/remotes/origin/" + defaultBranch,
		"refs/remotes/upstream/" + defaultBranch,
	} {
		if r.Ok("show-ref", "--verify", "--quiet", ref) {
			return ref
		}
	}
	return ""
}

type mergedBranch struct {
	name   string
	wtPath string
}

func listMergedBranches(r *gitcmd.Runner, targetRef string) ([]mergedBranch, error) {
	// Specify --sort=refname so global branch.sort config does not change ordering.
	raw, err := r.OutputRaw("for-each-ref", "--sort=refname", "--merged="+targetRef, "--format=%(refname:short)%00%(worktreepath)", "refs/heads/")
	if err != nil {
		return nil, err
	}

	var result []mergedBranch
	for lineBytes := range bytes.SplitSeq(raw, []byte{'\n'}) {
		if len(lineBytes) == 0 {
			continue
		}
		branchBytes, wtBytes, ok := bytes.Cut(lineBytes, []byte{0})
		branch := string(branchBytes)
		if branch == "" {
			continue
		}
		var wtPath string
		if ok {
			wtPath = string(wtBytes)
		}
		result = append(result, mergedBranch{name: branch, wtPath: wtPath})
	}
	return result, nil
}

func resolveRealPath(path string) string {
	abs, err := filepath.Abs(path)
	if err != nil {
		return filepath.Clean(path)
	}
	resolved, err := filepath.EvalSymlinks(abs)
	if err != nil {
		return abs
	}
	return resolved
}

func isSameOrInside(parentDir, targetPath string) bool {
	rel, err := filepath.Rel(parentDir, targetPath)
	if err != nil {
		return false
	}
	return rel == "." || (rel != ".." && !strings.HasPrefix(rel, ".."+string(filepath.Separator)))
}

func isDir(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.IsDir()
}

func resolveDeleteRunner(r *gitcmd.Runner, ctx gitcmd.RepoContext, defaultBranch, defaultWT string) *gitcmd.Runner {
	if defaultWT != "" && isDir(defaultWT) {
		return r.InDir(defaultWT)
	}
	if ctx.IsBare {
		commonRunner := r.InDir(ctx.CommonDir)
		if head, err := commonRunner.Output("symbolic-ref", "--short", "HEAD"); err == nil && head == defaultBranch {
			return commonRunner
		}
	}
	return r
}

func run(args []string, workDir string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("git-delete-merged-branches", flag.ContinueOnError)
	fs.SetOutput(stderr)
	dryRun := fs.Bool("dry-run", false, "show actions without removing worktrees or deleting branches")

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git-delete-merged-branches [--dry-run]\n\n")
		fmt.Fprintf(stderr, "Remove local branches merged into the default branch and their clean linked worktrees.\n\n")
		fs.PrintDefaults()
	}

	if err := fs.Parse(args); err != nil {
		return err
	}
	if len(fs.Args()) != 0 {
		fs.Usage()
		return fmt.Errorf("expected no positional arguments, got %d", len(fs.Args()))
	}

	cwd := workDir
	if cwd == "" {
		var err error
		cwd, err = os.Getwd()
		if err != nil {
			return fmt.Errorf("resolve working directory: %w", err)
		}
	}
	cwdReal := resolveRealPath(cwd)

	ctx, err := gitcmd.DetectRepoContext(cwd, stdout, stderr)
	if err != nil {
		return err
	}

	r := gitcmd.NewIsolated(ctx.ContainerDir, stdout, stderr)
	defaultBranch, err := gitcmd.DetectDefaultBranch(r, ctx.CommonDir, ctx.IsBare)
	if err != nil || defaultBranch == "" {
		return nil
	}
	targetRef := resolveTargetRef(r, defaultBranch)
	if targetRef == "" {
		return nil
	}

	if !*dryRun {
		if err := r.Stream("worktree", "prune"); err != nil {
			return err
		}
	}

	defaultWT, _ := gitcmd.FindBranchWorktree(r, defaultBranch)
	merged, err := listMergedBranches(r, targetRef)
	if err != nil {
		return err
	}

	deleteRunner := resolveDeleteRunner(r, ctx, defaultBranch, defaultWT)

	for _, entry := range merged {
		if entry.name == defaultBranch || gitcmd.IsProtectedBranch(entry.name) {
			continue
		}

		if entry.wtPath != "" && isDir(entry.wtPath) {
			wtReal := resolveRealPath(entry.wtPath)
			if isSameOrInside(wtReal, cwdReal) {
				fmt.Fprintf(stderr, "Skipping merged branch %s (currently inside worktree %s)\n", entry.name, entry.wtPath)
				continue
			}

			if *dryRun {
				fmt.Fprintf(stdout, "[dry-run] git worktree remove %s\n", entry.wtPath)
			} else if err := r.Stream("worktree", "remove", entry.wtPath); err != nil {
				// Never pass --force so dirty worktrees or main worktrees stay safe.
				fmt.Fprintf(stderr, "Keeping worktree %s for branch %s\n", entry.wtPath, entry.name)
				continue
			}
		}

		if *dryRun {
			fmt.Fprintf(stdout, "[dry-run] git branch --delete %s\n", entry.name)
			continue
		}
		if err := deleteRunner.Stream("branch", "--delete", entry.name); err != nil {
			return err
		}
	}

	if !*dryRun {
		if err := r.Stream("worktree", "prune"); err != nil {
			return err
		}
	}
	return nil
}

func main() {
	if err := run(os.Args[1:], "", os.Stdout, os.Stderr); err != nil {
		if !errors.Is(err, flag.ErrHelp) {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		}
		os.Exit(1)
	}
}
