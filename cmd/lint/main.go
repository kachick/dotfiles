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
	exhaustructResult, err := exec.Command("go", []string{"tool", "-n", "exhaustruct"}...).CombinedOutput()
	if err != nil {
		log.Fatalf("Missing exhaustruct as a vettool: %+v", err)
	}

	// It downloads dependencies and outputs them in first run. So getting only last line here such as tail command
	var last string
	for line := range strings.Lines(string(exhaustructResult)) {
		last = line
	}
	return strings.TrimSpace(last)
}

func main() {
	allFlag := flag.Bool("all", false, "includes heavy linters")

	flag.Parse()

	walker := fileutils.GetWalker()

	bashPaths := walker.GetAllBash()
	markdownPaths := walker.GetAllMarkdown()

	// Don't add secrets scanner here. It should be done in pre-push hook now.
	cmds := runner.Commands{
		{Path: "shellcheck", Args: bashPaths},
		{Path: "typos", Args: constants.GetTyposTargetedRoots()},
		{Path: "go", Args: []string{"vet", "-vettool", getExhaustructPath(), "./..."}},
		{Path: "nixpkgs-lint", Args: []string{"."}},
		{Path: "markdownlint-cli2", Args: markdownPaths},
		// Add selfup as `git ls-files | xargs selfup list -check`. Consider https://github.com/kachick/dotfiles/issues/905 for use of pipe
	}

	if *allFlag {
		// FIXME: Adding lychee here making Network error
		cmds = append(cmds, runner.Cmd{Path: "trivy", Args: []string{"config", "--exit-code", "1", "."}})
		cmds = append(cmds, runner.Cmd{Path: "nix", Args: []string{"run", ".#check_nixf"}})
	}

	cmds.ParallelRun()
}
