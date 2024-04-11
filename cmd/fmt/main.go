//go:build linux || darwin

package main

import (
	"flag"

	"github.com/kachick/dotfiles/internal/fileutils"
	"github.com/kachick/dotfiles/internal/runner"
)

func main() {
	allFlag := flag.Bool("all", false, "includes heavy linters")

	flag.Parse()

	walker := fileutils.GetWalker()

	bashPaths := walker.GetAllBash()
	nixPaths := walker.GetAllNix()

	// Do not cover the same files in another formatter for parallel processing
	cmds := runner.Commands{
		{Path: "dprint", Args: []string{"fmt"}},
		{Path: "shfmt", Args: append([]string{"--language-dialect", "bash", "--write"}, bashPaths...)},
		{Path: "go", Args: []string{"fmt", "./..."}},
	}

	if *allFlag {
		// nix fmt doesn't respect .gitignore, without paths, .direnv included: https://github.com/NixOS/nixfmt/issues/151
		// nixfmt-rfc-style looks like using cache, if update with empty commit, it takes longtime
		cmds = append(cmds, runner.Cmd{Path: "nix", Args: append([]string{"fmt"}, nixPaths...)})
	}

	cmds.ParallelRun()
}
