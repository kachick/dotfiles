//go:build linux || darwin

package main

import (
	"github.com/kachick/dotfiles"
)

// List of official resources:
//   - https://channels.nixos.org
//   - https://releases.nixos.org

// Other candidates
//   - https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
//   - https://github.com/nix-community/home-manager/archive/release-23.05.tar.gz home-manager

func main() {

	cmds := dotfiles.Commands{
		{Path: "nix-channel", Args: []string{"--add", "https://releases.nixos.org/nixpkgs/nixpkgs-23.11pre511546.844ffa82bbe2/nixexprs.tar.xz", "nixpkgs"}},
		{Path: "nix-channel", Args: []string{"--add", "https://github.com/nix-community/home-manager/archive/a8f8f48320c64bd4e3a266a850bbfde2c6fe3a04.tar.gz", "home-manager"}},
		{Path: "nix-channel", Args: []string{"--update"}},
		{Path: "nix-channel", Args: []string{"--list"}},
	}

	cmds.SequentialRun()
}
