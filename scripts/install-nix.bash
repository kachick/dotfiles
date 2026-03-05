#!/usr/bin/env bash
set -eux -o pipefail

# This script installs Nix and configures binary caches from the dotfiles flake.
# Usage:
#   ./scripts/install-nix.bash [FLAKE_URI]

TARGET_FLAKE="${1:-github:kachick/dotfiles}"

# 1. Install Nix in multi-user mode
if ! command -v nix >/dev/null 2>&1; then
	echo "Installing Nix..."
	# https://github.com/NixOS/nix-installer
	curl --proto '=https' --tlsv1.2 -sSf -L https://artifacts.nixos.org/nix-installer | sh -s -- install linux \
		--extra-conf "sandbox = false" \
		--extra-conf "trusted-users = root @wheel" \
		--no-confirm
	# shellcheck source=/dev/null
	. /etc/profile.d/nix.sh
fi

# 2. Configure binary caches into nix.custom.conf
# We run the gen-nix-cache-conf app from the flake.
echo "Configuring binary caches from ${TARGET_FLAKE}..."
nix run --accept-flake-config "${TARGET_FLAKE}#gen-nix-cache-conf" | sudo tee /etc/nix/nix.custom.conf
sudo systemctl restart nix-daemon

echo "✅ Nix setup completed!"
