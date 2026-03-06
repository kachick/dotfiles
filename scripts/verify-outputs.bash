#!/usr/bin/env bash
set -euo pipefail

# This script verifies that flake outputs and configurations are correctly
# structured and that overlays are properly applied.

echo "Checking top-level overlays..."
nix eval .#overlays.default --apply builtins.isFunction --json

echo "Checking package overlays (mozc patches)..."
# GH-1277.patch should be present in mozc if overlays are applied correctly.
# This check is pure since mozc is a free package.
nix eval .#packages.x86_64-linux.mozc.patches --json | grep -q "GH-1277.patch"

echo "Checking Home Manager configuration (kachick@wsl-ubuntu) for overlays..."
# Unstable package set should be accessible if overlays are applied correctly.
nix eval .#homeConfigurations."kachick@wsl-ubuntu".pkgs.unstable.lib.version --json

echo "Verification successful!"
