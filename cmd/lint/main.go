//go:build linux || darwin

package main

import (
	"flag"
	"log"
	"os/exec"
	"strings"

	"github.com/kachick/dotfiles/internal/constants"
	"github.com/kachick/dotfiles/internal/fileutils"
	"github.com/kachick/dotfiles/internal/runner"
)

func getExhaustructPath() string {
	// It downloads dependencies and outputs them in first run.
	// And getting only last line made messy result. I didn't get the actual root cause of this problem... :<
	goToolN := func() *exec.Cmd { return exec.Command("go", []string{"tool", "-n", "exhaustruct"}...) }
	err := goToolN().Run()
	if err != nil {
		log.Fatalf("Failed to run `go tool -n`: %+v", err)
	}

	exhaustructResult, err := goToolN().CombinedOutput()
	if err != nil {
		log.Fatalf("Missing exhaustruct as a vettool: %+v", err)
	}

	return strings.TrimSpace(string(exhaustructResult))
}

func main() {
	allFlag := flag.Bool("all", false, "includes heavy linters")

	flag.Parse()

	walker := fileutils.GetWalker()

	bashPaths := walker.GetAllBash()
	markdownPaths := walker.GetAllMarkdown()

	// Don't add secrets scanner here. It should be done in pre-push hook now.
	linters := runner.Commands{
		{Path: "shellcheck", Args: bashPaths},
		{Path: "typos", Args: constants.GetTyposTargetedRoots()},
		// Add selfup as `git ls-files | xargs selfup list -check`. Consider https://github.com/kachick/dotfiles/issues/905 for use of pipe
	}

	heavyOrTrivial := runner.Commands{
		// FIXME: Adding lychee here making Network error
		{Path: "go", Args: []string{"vet", "-vettool", getExhaustructPath(), "./..."}},
		{Path: "nixpkgs-lint", Args: []string{"."}},
		{Path: "markdownlint-cli2", Args: markdownPaths},
		{Path: "trivy", Args: []string{"config", "--exit-code", "1", "."}},
		{Path: "nix", Args: []string{"run", ".#check_nixf"}},
	}

	if *allFlag {
		linters = append(linters, heavyOrTrivial...)
	}

	linters.ParallelRun()
}
