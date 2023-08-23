//go:build linux || darwin

package main

import (
	"dotfiles/internal/constants"
	"dotfiles/internal/fileutils"
	"dotfiles/internal/runner"
)

func main() {
	walker := fileutils.GetWalker()

	bashPaths := walker.GetAllBash()
	nixPaths := walker.GetAllNix()

	cmds := runner.Commands{
		{Path: "dprint", Args: []string{"check"}},
		{Path: "shfmt", Args: append([]string{"--language-dialect", "bash", "--diff"}, bashPaths...)},
		{Path: "shellcheck", Args: bashPaths},
		{Path: "nixpkgs-fmt", Args: append([]string{"--check"}, nixPaths...)},
		{Path: "typos", Args: constants.GetTyposTargetedRoots()},
		{Path: "gitleaks", Args: []string{"detect"}},
		{Path: "go", Args: []string{"vet", "./..."}},
	}

	cmds.ParallelRun()
}
