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

func main() {
	allFlag := flag.Bool("all", false, "includes heavy linters")

	flag.Parse()

	walker := fileutils.GetWalker()

	bashPaths := walker.GetAllBash()
	markdownPaths := walker.GetAllMarkdown()

	rawExhaustructPath, err := exec.Command("go", []string{"tool", "-n", "exhaustruct"}...).CombinedOutput()
	if err != nil {
		log.Fatalf("Missing exhaustruct as a vettool: %+v", err)
	}
	exhaustructPath := strings.TrimSpace(string(rawExhaustructPath))

	// Don't add secrets scanner here. It should be done in pre-push hook now.
	cmds := runner.Commands{
		{Path: "shellcheck", Args: bashPaths},
		{Path: "typos", Args: constants.GetTyposTargetedRoots()},
		{Path: "go", Args: []string{"vet", "-vettool", exhaustructPath, "./..."}},
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
