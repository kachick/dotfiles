#!/usr/bin/env bash

set -euo pipefail

# This script verifies the sample flake.nix by running it against the local repository state.

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

REPO_ROOT=$(pwd)
SAMPLE_FLAKE="$REPO_ROOT/nixos/hosts/generic/flake.nix"

echo "Testing sample flake in $TMP_DIR..."

# 1. Copy sample flake
cp "$SAMPLE_FLAKE" "$TMP_DIR/flake.nix"

# 2. Point dotfiles to the local repo path for testing
# We use a simple sed to replace the URL for testing purposes
sed -i "s|github:kachick/dotfiles|path:$REPO_ROOT|g" "$TMP_DIR/flake.nix"

# 3. Create a dummy hardware-configuration.nix to satisfy evaluation
cat >"$TMP_DIR/hardware-configuration.nix" <<EOF
{ ... }: {
  fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };
  boot.loader.systemd-boot.enable = true;
  nixpkgs.hostPlatform = "x86_64-linux";
}
EOF

# 4. Run dry-run build
cd "$TMP_DIR"
nix build ".#nixosConfigurations.sample.config.system.build.toplevel" --dry-run --show-trace

echo "✅ Sample flake evaluation succeeded!"
