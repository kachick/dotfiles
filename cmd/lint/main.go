//go:build linux

package main

import (
	"flag"
	"log"

	"github.com/kachick/dotfiles/cmd/lint/internal/fileutils"
	"github.com/kachick/dotfiles/cmd/lint/internal/repocheck"
	"github.com/kachick/dotfiles/cmd/lint/internal/runner"
)

var typosTargetedRoots = []string{
	".",
	".github",
	".vscode",
}

func main() {
	allFlag := flag.Bool("all", false, "includes heavy linters")

	flag.Parse()

	log.SetFlags(log.Flags() &^ (log.Ldate | log.Ltime))

	// Format checks should run before parallel linters to fail early and avoid conflicts.
	formatters := runner.Commands{
		{Path: "dprint", Args: []string{"check"}},
	}
	if err := formatters.SequentialRun(); err != nil {
		log.Fatalln(err)
	}

	walker, err := fileutils.GetWalker()
	if err != nil {
		log.Fatalln(err)
	}

	bashPaths := walker.GetAllBash()
	nixPaths := walker.GetAllNix()
	desktopPaths := walker.GetAllDesktop()

	// Don't add secrets scanner here. It should be done in pre-push hook now.
	linters := runner.Commands{
		{Path: "shellcheck", Args: bashPaths},
		{Path: "typos", Args: typosTargetedRoots},
		{Path: "go", Args: []string{"vet", "./..."}},
		{Path: "nixf-diagnose", Args: append([]string{"--"}, nixPaths...)},
	}

	heavyOrTrivial := runner.Commands{
		{Path: "rumdl", Args: []string{"check", "."}},
		{Path: "zizmor", Args: []string{"--pedantic", "."}},
		{Path: "ghadiag", Args: []string{}},
		{Path: "kanata", Args: []string{"--check", "--cfg", "config/keyboards/kanata.kbd"}},
	}
	if len(desktopPaths) > 0 {
		heavyOrTrivial = append(heavyOrTrivial, runner.Cmd{
			Path: "desktop-file-validate",
			Args: desktopPaths,
		})
	}

	if *allFlag {
		linters = append(linters, heavyOrTrivial...)
	}

	if err := repocheck.RunAll("."); err != nil {
		log.Fatalln(err)
	}

	if err := linters.ParallelRun(); err != nil {
		log.Fatalln(err)
	}
}
