#!/usr/bin/env bash
set -eux -o pipefail

# This script installs Nix and configures binary caches from the dotfiles flake.
# Usage:
#   curl ... | bash -s -- [REVISION]

TARGET_REV="${1:-main}"
TARGET_FLAKE="github:kachick/dotfiles/${TARGET_REV}"

# 1. Install Nix in multi-user mode
if ! command -v nix >/dev/null 2>&1; then
	echo "Installing Nix..."
	# https://github.com/NixOS/nix-installer
	# The installer will auto-detect the OS if not specified.
	curl --proto '=https' --tlsv1.2 -sSf -L https://artifacts.nixos.org/nix-installer | sh -s -- install \
		--extra-conf "sandbox = false" \
		--extra-conf "trusted-users = root @wheel @sudo $USER" \
		--no-confirm

	# shellcheck source=/dev/null
	if [ "$(uname)" = "Linux" ]; then
		. /etc/profile.d/nix.sh
	elif [ "$(uname)" = "Darwin" ]; then
		. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
	fi
fi

# 2. Configure binary caches into nix.custom.conf
# We run the gen-nix-cache-conf app from the flake.
# NOTE: This assumes /etc/nix/nix.conf has 'include nix.custom.conf' or similar setup.
echo "Configuring binary caches from ${TARGET_FLAKE}..."
nix run --accept-flake-config "${TARGET_FLAKE}#gen-nix-cache-conf" | sudo tee /etc/nix/nix.custom.conf

if command -v systemctl >/dev/null 2>&1; then
	sudo systemctl restart nix-daemon
fi

echo "✅ Nix setup completed!"
