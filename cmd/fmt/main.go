//go:build linux || darwin

package main

import (
	"dotfiles/internal/fileutils"
	"dotfiles/internal/runner"
)

func main() {
	wr := fileutils.GetWalker()

	bashPaths := wr.GetAllBash()
	nixPaths := wr.GetAllNix()

	// Do not cover the same files in another formatter for parallel processing
	cmds := runner.Commands{
		{Path: "dprint", Args: []string{"fmt"}},
		{Path: "shfmt", Args: append([]string{"--language-dialect", "bash", "--write"}, bashPaths...)},
		{Path: "nixpkgs-fmt", Args: nixPaths},
		{Path: "typos", Args: append(fileutils.GetTyposTargetedRoots(), "--write-changes")},
		{Path: "go", Args: []string{"fmt", "./..."}},
	}

	cmds.ParallelRun()
}
