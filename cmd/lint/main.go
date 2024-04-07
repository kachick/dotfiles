//go:build linux || darwin

package main

import (
	"github.com/kachick/dotfiles/internal/constants"
	"github.com/kachick/dotfiles/internal/fileutils"
	"github.com/kachick/dotfiles/internal/runner"
)

func main() {
	walker := fileutils.GetWalker()

	bashPaths := walker.GetAllBash()

	cmds := runner.Commands{
		{Path: "dprint", Args: []string{"check"}},
		{Path: "shfmt", Args: append([]string{"--language-dialect", "bash", "--diff"}, bashPaths...)},
		{Path: "shellcheck", Args: bashPaths},
		// nix fmt doesn't have check option: https://github.com/NixOS/nix/issues/6918, so do not include here
		{Path: "typos", Args: constants.GetTyposTargetedRoots()},
		{Path: "gitleaks", Args: []string{"detect"}},
		{Path: "go", Args: []string{"vet", "./..."}},
		{Path: "trivy", Args: []string{"config", "--exit-code", "1", "."}},
	}

	cmds.ParallelRun()
}
