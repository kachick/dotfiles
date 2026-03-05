#!/usr/bin/env bash

# This script verifies that the sample flake.nix in nixos/hosts/sample/
# correctly evaluates against the current repository state.
#
# Usage:
#   ./scripts/test-sample-nixos.bash
#
# Prerequisite:
#   Must be executed from the repository root.

set -euo pipefail

REPO_ROOT=$(pwd)
SAMPLE_DIR=$(dirname "$(realpath "$0")")
SAMPLE_FLAKE="$SAMPLE_DIR/flake.nix"

echo "Checking sample flake evaluation against local repository state..."

# 1. Setup testing environment in a temporary directory
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
cp "$SAMPLE_FLAKE" "$TMP_DIR/flake.nix"

# Create a dummy hardware-configuration.nix to satisfy evaluation requirements
cat >"$TMP_DIR/hardware-configuration.nix" <<EOF
{ ... }: {
  fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };
  nixpkgs.hostPlatform = "x86_64-linux";
}
EOF

# 2. Point the dotfiles input to the local repository path
# This ensures we are testing the current PR/commit changes.
sed -i "s|github:kachick/dotfiles|path:$REPO_ROOT|g" "$TMP_DIR/flake.nix"

# 3. Perform dry-run build
# If this fails, the script will exit with a non-zero code due to 'set -e'.
cd "$TMP_DIR"
nix build ".#nixosConfigurations.sample.config.system.build.toplevel" --dry-run --show-trace

echo "✅ Sample flake evaluation succeeded!"
