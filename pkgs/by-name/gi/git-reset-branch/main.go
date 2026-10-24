package main

import (
	"crypto/rand"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
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

type runner struct {
	dir    string
	stdout io.Writer
	stderr io.Writer
}

func (r *runner) git(args ...string) (string, error) {
	cmd := exec.Command("git", args...)
	if r.dir != "" {
		cmd.Dir = r.dir
	}
	out, err := cmd.CombinedOutput()
	outputStr := strings.TrimSpace(string(out))
	if err != nil {
		return outputStr, fmt.Errorf("git %s failed: %w: %s", strings.Join(args, " "), err, outputStr)
	}
	return outputStr, nil
}

func run(args []string, workDir string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("git-reset-branch", flag.ContinueOnError)
	fs.SetOutput(stderr)

	remote := fs.String("remote", "origin", "remote name to fetch from")
	dryRun := fs.Bool("dry-run", false, "show actions without modifying repository")

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git-reset-branch [options] [branch]\n\n")
		fmt.Fprintf(stderr, "Reset a local branch to match its remote tracking branch safely.\n")
		fmt.Fprintf(stderr, "The previous state of the local branch is backed up as backup-<branch>-<uuid>.\n")
		fmt.Fprintf(stderr, "If [branch] is omitted, the current branch is used.\n\n")
		fmt.Fprintf(stderr, "Options:\n")
		fs.PrintDefaults()
	}

	if err := fs.Parse(args); err != nil {
		return err
	}

	r := &runner{dir: workDir, stdout: stdout, stderr: stderr}

	// Ensure we are inside a Git work tree
	if _, err := r.git("rev-parse", "--is-inside-work-tree"); err != nil {
		return errors.New("not inside a git repository")
	}

	// Determine target branch
	var targetBranch string
	remainingArgs := fs.Args()
	if len(remainingArgs) == 0 {
		current, err := r.git("symbolic-ref", "--short", "HEAD")
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

	// Check for dirty working tree
	status, err := r.git("status", "--porcelain")
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
		if _, err := r.git("fetch", *remote, targetBranch); err != nil {
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
	current, _ := r.git("symbolic-ref", "--short", "HEAD")
	if current != targetBranch {
		if _, err := r.git("switch", targetBranch); err != nil {
			return fmt.Errorf("failed to switch to branch '%s': %w", targetBranch, err)
		}
	}

	// Rename current target branch to backup branch.
	//
	// Why not git reset --hard:
	// A hard reset drops local commits into reflog, which is easy to lose by mistake.
	// Renaming to a backup branch keeps all commits safe and easy to restore.
	if _, err := r.git("branch", "-m", backupBranch); err != nil {
		return fmt.Errorf("failed to rename branch '%s' to '%s': %w", targetBranch, backupBranch, err)
	}

	// Checkout fresh branch from remote
	remoteRef := fmt.Sprintf("%s/%s", *remote, targetBranch)
	if _, err := r.git("checkout", "-b", targetBranch, remoteRef); err != nil {
		return fmt.Errorf("failed to recreate branch '%s' from '%s': %w", targetBranch, remoteRef, err)
	}

	fmt.Fprintf(stdout, "Successfully reset branch '%s' to '%s'. (Previous state backed up as '%s')\n", targetBranch, remoteRef, backupBranch)
	return nil
}

func main() {
	if err := run(os.Args[1:], "", os.Stdout, os.Stderr); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %s\n", err)
		os.Exit(1)
	}
}
