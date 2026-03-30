#!/usr/bin/env -S bash

set -euxo pipefail

git config --global --add safe.directory /provisioner/dotfiles
nix run '/provisioner/dotfiles#home-manager' -- switch -b backup --flake '/provisioner/dotfiles/#user@container'

# Do NOT run 'nix store gc' here.
# 1. It makes the build slower by deleting packages that could be reused in the next incremental build.
# 2. In a container layer structure, deleting files in a new layer does NOT reduce the total image size;
#    it only adds a 'deletion' record while the original files remain in the base layer.
# 3. Periodic full rebuilds (Squash) are a better way to clean up the store and reduce image size.
