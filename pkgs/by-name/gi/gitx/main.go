package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
)

type gitxSubcommand struct {
	name        string
	description string
	run         func(args []string, stdin io.Reader, stdout, stderr io.Writer) error
}

func allGitxSubcommands() []gitxSubcommand {
	return []gitxSubcommand{
		{
			name:        "menu",
			description: "Unified interactive fzf/gum launcher for worktrees, branches, logs, tags, and repos",
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				return runMenu(args, "", stdout, stderr)
			},
		},
		{
			name:        "wt",
			description: "Manage flat git worktrees in clean-bare repositories",
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				return runWT(args, "", stdout, stderr)
			},
		},
		{
			name:        "refresh",
			description: "Update remotes and fast-forward the default branch",
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				return runRefresh(args, "", stdout, stderr)
			},
		},
		{
			name:        "delete-merged-branches",
			description: "Remove merged local branches and clean worktrees",
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				return runDeleteMergedBranches(args, "", stdout, stderr)
			},
		},
		{
			name:        "init-clean-bare",
			description: "Initialize default branch worktree for a bare repository",
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				return runInitCleanBare(args, stdout, stderr)
			},
		},
		{
			name:        "get",
			description: "Clone a repository in clean-bare layout and print its worktree path",
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				return runGet(args, stdout, stderr)
			},
		},
		{
			name:        "migrate-clean-bare",
			description: "Convert a repository into the clean-bare layout",
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				return runMigrateCleanBare(args, "", stdout, stderr)
			},
		},
		{
			name:        "reset-branch",
			description: "Safely reset a local branch to match its remote",
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				return runResetBranch(args, "", stdout, stderr)
			},
		},
		{
			name:        "show",
			description: "Show commit details (--ja translates commit messages)",
			run: func(args []string, stdin io.Reader, stdout, stderr io.Writer) error {
				return runShow(args, "", stdin, stdout, stderr)
			},
		},
		{
			name:        "log-fzf",
			description: "Interactive git log searcher (--ja enables translation)",
			run: func(args []string, stdin io.Reader, stdout, stderr io.Writer) error {
				return runLogFzf(args, stdin, stdout, stderr)
			},
		},
		{
			name:        "resolve-conflict",
			description: "Open unresolved conflict locations in helix",
			run: func(args []string, stdin io.Reader, stdout, stderr io.Writer) error {
				return runResolveConflict(args, "", stdin, stdout, stderr)
			},
		},
		{
			name:        "hooks",
			description: "Run configured Git hooks (pre-push)",
			run: func(args []string, stdin io.Reader, stdout, stderr io.Writer) error {
				return runHooks(args, stdin, stdout, stderr)
			},
		},
		{
			name:        "repo-fzf",
			description: "Select a repository worktree via fzf",
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				return runRepoFzf(args, stdout, stderr)
			},
		},
		{
			name:        "gh-reponame",
			description: "Extract repository name from OWNER/REPO or GitHub URL",
			run: func(args []string, stdin io.Reader, stdout, stderr io.Writer) error {
				return runGhReponame(args, stdin, stdout, stderr)
			},
		},
		{
			name:        "commit-from-history",
			description: "Commit all changes using a shell history entry selected via fzf",
			run: func(args []string, stdin io.Reader, stdout, stderr io.Writer) error {
				return runCommitFromHistory(args, "", stdin, stdout, stderr)
			},
		},
	}
}

func isGitxSubcommandName(name string) bool {
	for _, cmd := range allGitxSubcommands() {
		if cmd.name == name {
			return true
		}
	}
	return false
}

func printGitxUsage(w io.Writer) {
	fmt.Fprintf(w, "Usage: gitx <subcommand> [options] [args]\n\n")
	fmt.Fprintf(w, "Unified Git and GitHub workflow helper CLI.\n\n")
	fmt.Fprintf(w, "Subcommands:\n")
	for _, cmd := range allGitxSubcommands() {
		fmt.Fprintf(w, "  %-24s%s\n", cmd.name, cmd.description)
	}
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
	}

	for _, cmd := range allGitxSubcommands() {
		if cmd.name == subcmd {
			return cmd.run(rest, stdin, stdout, stderr)
		}
	}

	printGitxUsage(stderr)
	return fmt.Errorf("unknown subcommand: %s", subcmd)
}

func main() {
	if err := runGitx(os.Args[1:], os.Stdin, os.Stdout, os.Stderr); err != nil {
		if !errors.Is(err, flag.ErrHelp) {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		}
		os.Exit(1)
	}
}
