#!/bin/bash

set -euxo pipefail

nix-shell --packages git --command 'git config --global --add safe.directory /provisioner/dotfiles'
nix run '/provisioner/dotfiles#home-manager' -- switch -b backup --flake '/provisioner/dotfiles/#user'

# shellcheck disable=SC2016
nix shell '/provisioner/dotfiles#uinit' --command bash -c 'sudo "$(which uinit)" --user=user --dry_run=false'
# sudo chsh user -s "$HOME/.nix-profile/bin/zsh"

rm -rf /provisioner/dotfiles
nix store gc
