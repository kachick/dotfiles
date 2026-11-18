package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
)

func printGitxUsage(w io.Writer) {
	fmt.Fprintf(w, "Usage: gitx <subcommand> [options] [args]\n\n")
	fmt.Fprintf(w, "Unified Git, ghq, and GitHub workflow helper CLI.\n\n")
	fmt.Fprintf(w, "Subcommands:\n")
	fmt.Fprintf(w, "  wt                      Manage flat git worktrees in clean-bare repositories\n")
	fmt.Fprintf(w, "  refresh                 Update remotes and fast-forward the default branch\n")
	fmt.Fprintf(w, "  delete-merged-branches  Remove merged local branches and clean worktrees\n")
	fmt.Fprintf(w, "  init-clean-bare         Initialize default branch worktree for ghq --clean-bare\n")
	fmt.Fprintf(w, "  migrate-clean-bare      Convert a repository into the clean-bare layout\n")
	fmt.Fprintf(w, "  reset-branch            Safely reset a local branch to match its remote\n")
	fmt.Fprintf(w, "  show                    Show commit details (--ja translates commit messages)\n")
	fmt.Fprintf(w, "  log-fzf                 Interactive git log searcher (--ja enables translation)\n")
	fmt.Fprintf(w, "  resolve-conflict        Open unresolved conflict locations in helix\n")
	fmt.Fprintf(w, "  hooks                   Run configured Git hooks (pre-push)\n")
	fmt.Fprintf(w, "  ghq-fzf                 Select a ghq repository worktree via fzf\n")
	fmt.Fprintf(w, "  gh-reponame             Extract repository name from OWNER/REPO or GitHub URL\n")
}

func runGitx(args []string, stdin io.Reader, stdout, stderr io.Writer) error {
	if len(args) == 0 {
		printGitxUsage(stderr)
		return flag.ErrHelp
	}

	subcmd := args[0]
	rest := args[1:]

	switch subcmd {
	case "-h", "--help":
		printGitxUsage(stderr)
		return flag.ErrHelp
	case "help":
		printGitxUsage(stdout)
		return nil
	case "wt":
		return runWT(rest, "", stdout, stderr)
	case "refresh":
		return runRefresh(rest, "", stdout, stderr)
	case "delete-merged-branches":
		return runDeleteMergedBranches(rest, "", stdout, stderr)
	case "init-clean-bare":
		return runInitCleanBare(rest, stdout, stderr)
	case "migrate-clean-bare":
		return runMigrateCleanBare(rest, "", stdout, stderr)
	case "reset-branch":
		return runResetBranch(rest, "", stdout, stderr)
	case "show":
		return runShow(rest, "", stdin, stdout, stderr)
	case "log-fzf":
		return runLogFzf(rest, stdin, stdout, stderr)
	case "resolve-conflict":
		return runResolveConflict(rest, "", stdin, stdout, stderr)
	case "hooks":
		return runHooks(rest, stdin, stdout, stderr)
	case "ghq-fzf":
		return runGhqFzf(rest, stdout, stderr)
	case "gh-reponame":
		return runGhReponame(rest, stdin, stdout, stderr)
	default:
		printGitxUsage(stderr)
		return fmt.Errorf("unknown subcommand: %s", subcmd)
	}
}

func main() {
	if err := runGitx(os.Args[1:], os.Stdin, os.Stdout, os.Stderr); err != nil {
		if !errors.Is(err, flag.ErrHelp) {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		}
		os.Exit(1)
	}
}
