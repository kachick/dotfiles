//go:build linux

package main

import (
	"flag"
	"log"

	"github.com/kachick/dotfiles/internal/constants"
	"github.com/kachick/dotfiles/internal/fileutils"
	"github.com/kachick/dotfiles/internal/runner"
)

func main() {
	allFlag := flag.Bool("all", false, "includes heavy linters")

	flag.Parse()

	log.SetFlags(log.Flags() &^ (log.Ldate | log.Ltime))

	// Format checks should run before parallel linters to fail early and avoid conflicts.
	formatters := runner.Commands{
		{Path: "dprint", Args: []string{"check"}},
	}
	formatters.SequentialRun()

	walker := fileutils.GetWalker()

	bashPaths := walker.GetAllBash()
	nixPaths := walker.GetAllNix()

	// Don't add secrets scanner here. It should be done in pre-push hook now.
	linters := runner.Commands{
		{Path: "shellcheck", Args: bashPaths},
		{Path: "typos", Args: constants.GetTyposTargetedRoots()},
		{Path: "go", Args: []string{"vet", "./..."}},
		{Path: "nixf-diagnose", Args: append([]string{"--"}, nixPaths...)},
		// Add selfup as `git ls-files | xargs nix run github:kachick/selfup/v1.2.2 -- list -check`. Consider https://github.com/kachick/dotfiles/issues/905 for use of pipe
	}

	heavyOrTrivial := runner.Commands{
		{Path: "rumdl", Args: []string{"check", "."}},
		{Path: "trivy", Args: []string{"config", "--exit-code", "1", "."}},
		{Path: "zizmor", Args: []string{"--pedantic", "."}},
		{Path: "kanata", Args: []string{"--check", "--cfg", "config/keyboards/kanata.kbd"}},
		{Path: "desktop-file-validate", Args: []string{"config/keyboards/kanata-tray.desktop"}},
	}

	if *allFlag {
		linters = append(linters, heavyOrTrivial...)
	}

	linters.ParallelRun()
}
