#!/usr/bin/env bash

set -euxo pipefail

mkdir -p "$XDG_CONFIG_HOME/nix"
if [ -f "$XDG_CONFIG_HOME/nix/nix.conf" ]; then
  rg '^experimental-features' "$XDG_CONFIG_HOME/nix/nix.conf" ||
    echo 'experimental-features = nix-command flakes' >>"$XDG_CONFIG_HOME/nix/nix.conf"
fi
