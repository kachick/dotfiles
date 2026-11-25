package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
)

type gitXSubcommand struct {
	name            string
	description     string
	newFlags        func(stderr io.Writer) *flag.FlagSet
	flags           []cliFlagSpec
	flagValues      map[string][]string
	argKind         argCompletionKind
	argLabel        string
	argValues       []string
	supportsHelpCmd bool
	subcommands     func() []cliCommandSpec
	run             func(args []string, stdin io.Reader, stdout, stderr io.Writer) error
}

func allGitXSubcommands() []gitXSubcommand {
	return []gitXSubcommand{
		{
			name:        "menu",
			description: "Unified interactive fzf/gum launcher for worktrees, branches, logs, tags, and repos",
			newFlags: func(stderr io.Writer) *flag.FlagSet {
				fs, _ := newMenuFlagSet(stderr)
				return fs
			},
			flagValues: map[string][]string{
				"mode": menuModeNames(),
			},
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				if err := recoverDeletedWorkDir(stderr); err != nil {
					return err
				}
				return runMenu(args, "", stdout, stderr)
			},
		},
		{
			name:            "wt",
			description:     "Manage flat git worktrees in clean-bare repositories",
			supportsHelpCmd: true,
			subcommands:     wtCommandSpecs,
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				if err := recoverDeletedWorkDir(stderr); err != nil {
					return err
				}
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
			newFlags: func(stderr io.Writer) *flag.FlagSet {
				fs, _, _ := newDeleteMergedBranchesFlagSet(stderr)
				return fs
			},
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				return runDeleteMergedBranches(args, "", stdout, stderr)
			},
		},
		{
			name:        "init-clean-bare",
			description: "Initialize default branch worktree for a bare repository",
			newFlags: func(stderr io.Writer) *flag.FlagSet {
				fs, _ := newInitCleanBareFlagSet(stderr)
				return fs
			},
			argKind:  argCompleteDirs,
			argLabel: "directory",
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				return runInitCleanBare(args, stdout, stderr)
			},
		},
		{
			name:        "get",
			description: "Clone a repository in clean-bare layout and print its worktree path",
			newFlags: func(stderr io.Writer) *flag.FlagSet {
				fs, _ := newGetFlagSet(stderr)
				return fs
			},
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				return runGet(args, stdout, stderr)
			},
		},
		{
			name:        "sprout",
			description: "Create a private template repo on GitHub, clone it, enable auto-merge, and print its worktree path",
			newFlags: func(stderr io.Writer) *flag.FlagSet {
				return newSproutFlagSet(stderr)
			},
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				return runSprout(args, stdout, stderr)
			},
		},
		{
			name:        "migrate-clean-bare",
			description: "Convert a repository into the clean-bare layout",
			newFlags: func(stderr io.Writer) *flag.FlagSet {
				fs, _ := newMigrateCleanBareFlagSet(stderr)
				return fs
			},
			argKind:  argCompleteDirs,
			argLabel: "directory",
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				return runMigrateCleanBare(args, "", stdout, stderr)
			},
		},
		{
			name:        "reset-branch",
			description: "Safely reset a local branch to match its remote",
			newFlags: func(stderr io.Writer) *flag.FlagSet {
				fs, _, _ := newResetBranchFlagSet(stderr)
				return fs
			},
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				return runResetBranch(args, "", stdout, stderr)
			},
		},
		{
			name:        "show",
			description: "Show commit details (--ja translates commit messages)",
			flags:       showFlags(),
			run: func(args []string, stdin io.Reader, stdout, stderr io.Writer) error {
				return runShow(args, "", stdin, stdout, stderr)
			},
		},
		{
			name:        "log-fzf",
			description: "Interactive git log searcher (--ja enables translation)",
			flags:       logFzfFlags(),
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
			name:            "hooks",
			description:     "Run configured Git hooks (pre-push)",
			supportsHelpCmd: true,
			subcommands:     allHooksEvents,
			run: func(args []string, stdin io.Reader, stdout, stderr io.Writer) error {
				return runHooks(args, stdin, stdout, stderr)
			},
		},
		{
			name:        "repo-fzf",
			description: "Select a repository worktree via fzf",
			newFlags: func(stderr io.Writer) *flag.FlagSet {
				fs, _ := newRepoFzfFlagSet(stderr)
				return fs
			},
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
		{
			name:        "completion",
			description: "Generate shell completion script (bash or zsh)",
			argKind:     argCompleteValues,
			argLabel:    "shell",
			argValues:   supportedCompletionShells(),
			run: func(args []string, _ io.Reader, stdout, stderr io.Writer) error {
				return runCompletion(args, stdout, stderr)
			},
		},
	}
}

func isGitXSubcommandName(name string) bool {
	for _, cmd := range allGitXSubcommands() {
		if cmd.name == name {
			return true
		}
	}
	return false
}

func printGitXUsage(w io.Writer) {
	fmt.Fprintf(w, "Usage: git x <subcommand> [options] [args]\n\n")
	fmt.Fprintf(w, "Unified Git and GitHub workflow helper CLI.\n\n")
	fmt.Fprintf(w, "Subcommands:\n")
	for _, cmd := range allGitXSubcommands() {
		fmt.Fprintf(w, "  %-24s%s\n", cmd.name, cmd.description)
	}
}

func runGitX(args []string, stdin io.Reader, stdout, stderr io.Writer) error {
	if len(args) == 0 {
		printGitXUsage(stderr)
		return flag.ErrHelp
	}

	subcmd := args[0]
	rest := args[1:]

	switch subcmd {
	case "-h", "--help":
		printGitXUsage(stderr)
		return flag.ErrHelp
	case "help":
		printGitXUsage(stdout)
		return nil
	case "__complete":
		return runComplete(rest, stdout, stderr)
	}

	for _, cmd := range allGitXSubcommands() {
		if cmd.name == subcmd {
			return cmd.run(rest, stdin, stdout, stderr)
		}
	}

	printGitXUsage(stderr)
	return fmt.Errorf("unknown subcommand: %s", subcmd)
}

func main() {
	if err := runGitX(os.Args[1:], os.Stdin, os.Stdout, os.Stderr); err != nil {
		if !errors.Is(err, flag.ErrHelp) {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		}
		os.Exit(1)
	}
}
