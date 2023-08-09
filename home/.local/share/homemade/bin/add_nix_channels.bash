#!/usr/bin/env bash

set -euxo pipefail

# List of official resources:
#   - https://channels.nixos.org
#   - https://releases.nixos.org
nix-channel --add https://releases.nixos.org/nixpkgs/nixpkgs-23.11pre509044.3acb5c4264c4/nixexprs.tar.xz nixpkgs
# nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
# nix-channel --add https://github.com/nix-community/home-manager/archive/release-23.05.tar.gz home-manager
nix-channel --add https://github.com/nix-community/home-manager/archive/a8f8f48320c64bd4e3a266a850bbfde2c6fe3a04.tar.gz home-manager
nix-channel --update

nix-channel --list
