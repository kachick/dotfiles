#!/bin/bash
set -eux -o pipefail

# This script installs Nix in multi-user mode and configures binary caches.
# It is designed to be used both as a general-purpose installer and as a Lima provisioning script.

# 1. Install Nix (Multi-user / Daemon mode)
if ! command -v nix >/dev/null 2>&1; then
	echo "Installing Nix..."
	# Prepare initial bootstrap caches to speed up the first evaluation
	extra_conf_path="$(mktemp --suffix=.extra.nix.conf)"
	{
		echo 'experimental-features = nix-command flakes'
		echo "trusted-users = root $USER @wheel"
		echo "extra-substituters = https://kachick-dotfiles.cachix.org https://cache.nixos.org"
		echo "extra-trusted-public-keys = kachick-dotfiles.cachix.org-1:XhiP3JOkqNFGludaN+/send30shcrn1UMDeRL9XttkI= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
	} >>"$extra_conf_path"

	# Provide $HOME for the installer, otherwise it might fail in some environments
	export HOME="${HOME:-/root}"
	curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes --nix-extra-conf-file "$extra_conf_path"

	# Load Nix profile
	if [ -e /etc/profile.d/nix.sh ]; then
		# shellcheck source=/dev/null
		. /etc/profile.d/nix.sh
	fi
fi

# 2. Sync full binary cache list from Flake
# We use 'nix eval' to get the latest list defined in the repository.
# If this script is run within the repository, it uses the local flake.
# Otherwise, it falls back to the GitHub main branch.
TARGET_FLAKE="${1:-github:kachick/dotfiles/main}"

echo "Syncing binary caches from ${TARGET_FLAKE}..."

# Wait for nix-daemon to be ready
sleep 2

SUBSTITUTERS=$(nix eval --raw "${TARGET_FLAKE}#binary-caches.substituters" --apply 'builtins.concatStringsSep " "')
KEYS=$(nix eval --raw "${TARGET_FLAKE}#binary-caches.trusted-public-keys" --apply 'builtins.concatStringsSep " "')

{
	echo "extra-substituters = ${SUBSTITUTERS}"
	echo "extra-trusted-public-keys = ${KEYS}"
} | sudo tee -a /etc/nix/nix.conf

sudo systemctl restart nix-daemon

echo "✅ Nix installation and cache configuration completed!"
