#!/usr/bin/env -S bash

set -euxo pipefail

nix-shell --packages git --command 'git config --global --add safe.directory /provisioner/dotfiles'
nix run '/provisioner/dotfiles#home-manager' -- switch -b backup --flake '/provisioner/dotfiles/#user@linux-cli'
# Also we can call gc without sudo!
nix store gc
