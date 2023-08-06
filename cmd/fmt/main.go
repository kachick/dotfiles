package main

import (
	"github.com/kachick/dotfiles"
)

func main() {
	walker := dotfiles.GetWalker()

	bashPaths := walker.GetAllBash()
	nixPaths := walker.GetAllNix()

	// Do not cover the same files in another formatter for parallel processing
	cmds := dotfiles.Commands{
		{Path: "dprint", Args: []string{"fmt"}},
		{Path: "shfmt", Args: append([]string{"--language-dialect", "bash", "--write"}, bashPaths...)},
		{Path: "nixpkgs-fmt", Args: nixPaths},
		{Path: "typos", Args: append(dotfiles.GetTyposTargetedRoots(), "--write-changes")},
		{Path: "go", Args: []string{"fmt", "./..."}},
	}

	cmds.ParallelRun()
}
