package main

import (
	"github.com/kachick/dotfiles"
)

func main() {
	bashPaths := dotfiles.GetAllBash()
	nixPaths := dotfiles.GetAllNix()

	cmds := dotfiles.Commands{
		{Path: "dprint", Args: []string{"check"}},
		{Path: "shfmt", Args: append([]string{"--language-dialect", "bash", "--diff"}, bashPaths...)},
		{Path: "shellcheck", Args: bashPaths},
		{Path: "nixpkgs-fmt", Args: append([]string{"--check"}, nixPaths...)},
		{Path: "typos", Args: dotfiles.GetTyposTargetedRoots()},
		{Path: "gitleaks", Args: []string{"detect"}},
		{Path: "go", Args: []string{"vet", "./..."}},
	}

	cmds.ParallelRun()
}
