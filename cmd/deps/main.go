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
		// {Path: "gitleaks", Args: []string{"version"}},
		{Path: "stylua", Args: []string{"--version"}},
		{Path: "nixpkgs-lint", Args: []string{"--version"}},
		{Path: "goreleaser", Args: []string{"--version"}},
		{Path: "selfup", Args: []string{"-version"}},

		// Even if nixfmt returns old version as v0.5.0, the actual code is latest
		// https://github.com/NixOS/nixpkgs/pull/292625/files#diff-cf53ba433c9a367969e739cd32bc5a6fb9be271ed0ec604c34a3542a54ff1f5fR9-R12
		{Path: "nixfmt", Args: []string{"--version"}},
		// store path includes the date, but nix develop is too slow
		{Path: "bash", Args: []string{"-c", "which nixfmt"}},
	}

	// No side-effect commands, but keeping sequential for readability
	cmds.SequentialRun()
}
