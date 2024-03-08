#!/bin/bash

set -euxo pipefail

nix-shell --packages git --command 'git config --global --add safe.directory /tmp/dotfiles'
nix run '/tmp/dotfiles#home-manager' -- switch -b backup --flake '/tmp/dotfiles/#user'

# shellcheck disable=SC2016
nix shell '/tmp/dotfiles#uinit' --command bash -c 'sudo "$(which uinit)" --user=user --dry_run=false'
sudo chsh user -s "$HOME/.nix-profile/bin/zsh"

sudo rm -rf /tmp/dotfiles
nix store gc
