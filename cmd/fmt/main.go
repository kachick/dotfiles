//go:build linux || darwin

package main

import (
	"github.com/kachick/dotfiles/internal/fileutils"
	"github.com/kachick/dotfiles/internal/runner"
)

func main() {
	walker := fileutils.GetWalker()

	bashPaths := walker.GetAllBash()
	nixPaths := walker.GetAllNix()

	// Do not cover the same files in another formatter for parallel processing
	cmds := runner.Commands{
		{Path: "dprint", Args: []string{"fmt"}},
		{Path: "shfmt", Args: append([]string{"--language-dialect", "bash", "--write"}, bashPaths...)},
		// nix fmt doesn't respect .gitignore, without paths, .direnv included: https://github.com/NixOS/nixfmt/issues/151
		{Path: "nix", Args: append([]string{"fmt"}, nixPaths...)},
		{Path: "go", Args: []string{"fmt", "./..."}},
	}

	cmds.ParallelRun()
}
