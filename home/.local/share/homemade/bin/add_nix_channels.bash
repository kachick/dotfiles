#!/usr/bin/env bash

set -euxo pipefail

# List of official resources:
#   - https://channels.nixos.org
#   - https://releases.nixos.org
nix-channel --add https://releases.nixos.org/nixpkgs/nixpkgs-23.11pre509044.3acb5c4264c4/nixexprs.tar.xz nixpkgs
# nix-channel --add https://github.com/NixOS/nixpkgs/archive/c4147cd27248a85624f238413818c05c25ff3c0b.tar.gz nixpkgs
# nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
# nix-channel --add https://github.com/nix-community/home-manager/archive/release-23.05.tar.gz home-manager
nix-channel --add https://github.com/nix-community/home-manager/archive/729ab77f9e998e0989fa30140ecc91e738bc0cb1.tar.gz home-manager
nix-channel --update

nix-channel --list
