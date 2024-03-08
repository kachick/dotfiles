#!/bin/bash

set -euxo pipefail

nix-shell --packages git --command 'git config --local --add safe.directory /provisioner/dotfiles'
nix run '/provisioner/dotfiles#home-manager' -- switch -b backup --flake '/provisioner/dotfiles/#user'

rm -rf /provisioner/dotfiles
nix store gc
