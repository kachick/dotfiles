#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT=$(pwd)
SAMPLE_FLAKE="$REPO_ROOT/nixos/hosts/generic/flake.nix"

echo "=== Reproducing 'The option home-manager does not exist' ==="

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

cp "$SAMPLE_FLAKE" "$TMP_DIR/flake.nix"
sed -i "s|github:kachick/dotfiles|path:$REPO_ROOT|g" "$TMP_DIR/flake.nix"

cat >"$TMP_DIR/hardware-configuration.nix" <<EOF
{ ... }: {
  fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };
  boot.loader.systemd-boot.enable = true;
  nixpkgs.hostPlatform = "x86_64-linux";
}
EOF

cd "$TMP_DIR"

# Check if the evaluation fails with the reported error
if nix build ".#nixosConfigurations.sample.config.system.build.toplevel" --dry-run --show-trace 2>&1 | grep -q "The option .home-manager. does not exist"; then
	echo "SUCCESS: Error reproduced!"
else
	echo "FAILED: Still could not reproduce the error."
	nix build ".#nixosConfigurations.sample.config.system.build.toplevel" --dry-run --show-trace || true
fi
