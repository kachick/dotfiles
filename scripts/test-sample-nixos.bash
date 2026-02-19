#!/usr/bin/env bash

set -euo pipefail

# This script helps diagnose why 'nixosModules' might appear missing.

REPO_ROOT=$(pwd)
SAMPLE_FLAKE="$REPO_ROOT/nixos/hosts/generic/flake.nix"

echo "=== Diagnosis Start ==="

# 1. Check local flake attributes
echo "[1] Checking LOCAL flake attributes..."
nix eval --json ".#nixosModules" --apply "builtins.attrNames"

# 2. Setup testing environment
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
cp "$SAMPLE_FLAKE" "$TMP_DIR/flake.nix"

cat >"$TMP_DIR/hardware-configuration.nix" <<EOF
{ ... }: {
  fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };
  boot.loader.systemd-boot.enable = true;
  nixpkgs.hostPlatform = "x86_64-linux";
}
EOF

# 3. Test with LOCAL path (This should work)
echo -e "\n[2] Testing with LOCAL path (path:$REPO_ROOT)..."
sed -i "s|github:kachick/dotfiles|path:$REPO_ROOT|g" "$TMP_DIR/flake.nix"
cd "$TMP_DIR"
nix build ".#nixosConfigurations.sample.config.system.build.toplevel" --dry-run && echo "SUCCESS" || echo "FAILED"

# 4. Test with REMOTE URL (This might fail if pointing to main)
echo -e "\n[3] Testing with REMOTE URL (github:kachick/dotfiles)..."
# Re-copy to reset to remote URL
cp "$SAMPLE_FLAKE" "$TMP_DIR/flake.nix"
# NOTE: We don't run build here because it might fetch large amounts,
# just evaluate the attribute existence.
nix eval "github:kachick/dotfiles#nixosModules" --apply "builtins.attrNames" || echo "FAILED (As expected if change is not on main)"

echo -e "\n=== Diagnosis Finished ==="
