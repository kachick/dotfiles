//go:build linux || darwin

package main

import (
	"flag"

	"github.com/kachick/dotfiles/internal/constants"
	"github.com/kachick/dotfiles/internal/fileutils"
	"github.com/kachick/dotfiles/internal/runner"
)

func main() {
	allFlag := flag.Bool("all", false, "includes heavy linters")

	flag.Parse()

	walker := fileutils.GetWalker()

	bashPaths := walker.GetAllBash()
	markdownPaths := walker.GetAllMarkdown()

	cmds := runner.Commands{
		{Path: "shellcheck", Args: bashPaths},
		{Path: "typos", Args: constants.GetTyposTargetedRoots()},
		// No git makes 4x+ faster
		{Path: "gitleaks", Args: []string{"detect", "--no-git"}},
		{Path: "go", Args: []string{"vet", "./..."}},
		{Path: "nixpkgs-lint", Args: []string{"."}},
		{Path: "markdownlint-cli2", Args: markdownPaths},
		// Add selfup as `git ls-files | xargs selfup list -check`. Consider https://github.com/kachick/dotfiles/issues/905 for use of pipe
	}

	if *allFlag {
		cmds = append(cmds, runner.Cmd{Path: "trivy", Args: []string{"config", "--exit-code", "1", "."}})
		cmds = append(cmds, runner.Cmd{Path: "nix", Args: []string{"run", ".#check_nixf"}})
	}

	cmds.ParallelRun()
}
