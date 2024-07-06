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

	cmds := runner.Commands{
		{Path: "dprint", Args: []string{"check"}},
		{Path: "shfmt", Args: append([]string{"--language-dialect", "bash", "--diff"}, bashPaths...)},
		{Path: "shellcheck", Args: bashPaths},
		// nix fmt doesn't have check option: https://github.com/NixOS/nix/issues/6918, so do not include here
		{Path: "typos", Args: constants.GetTyposTargetedRoots()},
		// No git makes 4x+ faster
		{Path: "gitleaks", Args: []string{"detect", "--no-git"}},
		{Path: "go", Args: []string{"vet", "./..."}},
		{Path: "stylua", Args: []string{"--check", "."}},
		{Path: "nixpkgs-lint", Args: []string{"."}},
	}

	if *allFlag {
		cmds = append(cmds, runner.Cmd{Path: "trivy", Args: []string{"config", "--exit-code", "1", "."}})
	}

	cmds.ParallelRun()
}
