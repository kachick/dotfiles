//go:build linux || darwin

package main

import (
	"github.com/kachick/dotfiles/internal/runner"
)

func main() {
	cmds := runner.Commands{
		{Path: "go", Args: []string{"version"}},
		{Path: "makers", Args: []string{"--version"}},
		{Path: "nix", Args: []string{"--version"}},
		{Path: "dprint", Args: []string{"--version"}},
		{Path: "shellcheck", Args: []string{"--version"}},
		{Path: "shfmt", Args: []string{"--version"}},
		{Path: "typos", Args: []string{"--version"}},
		{Path: "gitleaks", Args: []string{"version"}},
	}

	cmds.SequentialRun()
}
