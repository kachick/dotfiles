package main

import (
	"crypto/rand"
	"errors"
	"flag"
	"fmt"
	"io"

	"github.com/kachick/dotfiles/internal/gitcmd"
)

// generateUUID generates an RFC 4122 v4 UUID without external dependencies.
//
// Why not external uuid package:
// Standard crypto/rand avoids adding new entries to go.mod.
//
// Why not shell out to nushell/uuidgen:
// Pure Go implementation keeps the binary self-contained and avoids shell escaping issues.
func generateUUID() (string, error) {
	var uuid [16]byte
	if _, err := io.ReadFull(rand.Reader, uuid[:]); err != nil {
		return "", err
	}
	// Set version to 4 (random)
	uuid[6] = (uuid[6] & 0x0f) | 0x40
	// Set variant to RFC 4122
	uuid[8] = (uuid[8] & 0x3f) | 0x80

	return fmt.Sprintf("%08x-%04x-%04x-%04x-%012x",
		uuid[0:4], uuid[4:6], uuid[6:8], uuid[8:10], uuid[10:16]), nil
}

func guardCleanBareDefaultWorktree(r *gitcmd.Runner, workDir, targetBranch string, stdout, stderr io.Writer) error {
	ctx, err := gitcmd.DetectRepoContext(workDir, stdout, stderr)
	if err != nil {
		return nil
	}
	commonRunner := gitcmd.NewIsolated(ctx.CommonDir, stdout, stderr)
	defaultBranch, err := gitcmd.DetectDefaultBranch(commonRunner, ctx.CommonDir, ctx.IsBare)
	if err != nil || defaultBranch == "" {
		return nil
	}
	topLevel, err := r.Output("rev-parse", "--path-format=absolute", "--show-toplevel")
	if err != nil || topLevel == "" {
		return nil
	}
	if gitcmd.IsCleanBareDefaultWorktree(ctx, defaultBranch, topLevel) && targetBranch != defaultBranch {
		return fmt.Errorf("cannot switch default worktree %s to non-default branch %q; use gitx wt instead", topLevel, targetBranch)
	}
	return nil
}

func newResetBranchFlagSet(stderr io.Writer) (*flag.FlagSet, *string, *bool) {
	fs := flag.NewFlagSet("gitx reset-branch", flag.ContinueOnError)
	fs.SetOutput(stderr)

	remote := fs.String("remote", "origin", "remote name to fetch from")
	dryRun := fs.Bool("dry-run", false, "show actions without modifying repository")

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: gitx reset-branch [options] [branch]\n\n")
		fmt.Fprintf(stderr, "Reset a local branch to match its remote tracking branch safely.\n")
		fmt.Fprintf(stderr, "The previous state of the local branch is backed up as backup-<branch>-<uuid>.\n")
		fmt.Fprintf(stderr, "If [branch] is omitted, the current branch is used.\n\n")
		fmt.Fprintf(stderr, "Options:\n")
		fs.PrintDefaults()
	}
	return fs, remote, dryRun
}

func runResetBranch(args []string, workDir string, stdout, stderr io.Writer) error {
	fs, remote, dryRun := newResetBranchFlagSet(stderr)

	if err := fs.Parse(args); err != nil {
		return err
	}

	r := gitcmd.New(workDir, stdout, stderr)

	// Ensure we are inside a Git work tree
	if _, err := r.Output("rev-parse", "--is-inside-work-tree"); err != nil {
		return errors.New("not inside a git repository")
	}

	// Determine target branch
	var targetBranch string
	remainingArgs := fs.Args()
	if len(remainingArgs) == 0 {
		current, err := r.Output("symbolic-ref", "--short", "HEAD")
		if err != nil || current == "" {
			return errors.New("cannot determine current branch (detached HEAD?); please specify a branch")
		}
		targetBranch = current
	} else if len(remainingArgs) == 1 {
		targetBranch = remainingArgs[0]
	} else {
		fs.Usage()
		return fmt.Errorf("expected at most 1 branch argument, got %d", len(remainingArgs))
	}

	if err := guardCleanBareDefaultWorktree(r, workDir, targetBranch, stdout, stderr); err != nil {
		return err
	}

	// Check for dirty working tree
	status, err := r.Output("status", "--porcelain")
	if err != nil {
		return err
	}
	if status != "" {
		return errors.New("working tree has uncommitted changes; please commit or stash them first")
	}

	// Fetch target branch from remote before touching any local branch
	if *dryRun {
		fmt.Fprintf(stdout, "[dry-run] git fetch %s %s\n", *remote, targetBranch)
	} else {
		if _, err := r.Output("fetch", *remote, targetBranch); err != nil {
			return fmt.Errorf("failed to fetch branch '%s' from remote '%s': %w", targetBranch, *remote, err)
		}
	}

	uuid, err := generateUUID()
	if err != nil {
		return fmt.Errorf("failed to generate uuid for backup branch: %w", err)
	}
	backupBranch := fmt.Sprintf("backup-%s-%s", targetBranch, uuid)

	if *dryRun {
		fmt.Fprintf(stdout, "[dry-run] git switch %s\n", targetBranch)
		fmt.Fprintf(stdout, "[dry-run] git branch -m %s\n", backupBranch)
		fmt.Fprintf(stdout, "[dry-run] git checkout -b %s %s/%s\n", targetBranch, *remote, targetBranch)
		return nil
	}

	// Switch to target branch if not already on it
	current, _ := r.Output("symbolic-ref", "--short", "HEAD")
	if current != targetBranch {
		if _, err := r.Output("switch", targetBranch); err != nil {
			return fmt.Errorf("failed to switch to branch '%s': %w", targetBranch, err)
		}
	}

	// Rename current target branch to backup branch.
	//
	// Why not git reset --hard:
	// A hard reset drops local commits into reflog, which is easy to lose by mistake.
	// Renaming to a backup branch keeps all commits safe and easy to restore.
	if _, err := r.Output("branch", "-m", backupBranch); err != nil {
		return fmt.Errorf("failed to rename branch '%s' to '%s': %w", targetBranch, backupBranch, err)
	}

	// Checkout fresh branch from remote
	remoteRef := fmt.Sprintf("%s/%s", *remote, targetBranch)
	if _, err := r.Output("checkout", "-b", targetBranch, remoteRef); err != nil {
		return fmt.Errorf("failed to recreate branch '%s' from '%s': %w", targetBranch, remoteRef, err)
	}

	fmt.Fprintf(stdout, "Successfully reset branch '%s' to '%s'. (Previous state backed up as '%s')\n", targetBranch, remoteRef, backupBranch)
	return nil
}
