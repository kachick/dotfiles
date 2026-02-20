#!/bin/bash
set -eux -o pipefail

# 2. Apply home-manager
# Step 3 in README Ubuntu section
mkdir -p ~/.local/state/nix/profiles

# Ensure Nix is in PATH.
export PATH="/nix/var/nix/profiles/default/bin:$PATH"
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
	. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Apply home-manager configuration using the provided Flake URI.
# $PARAM_FLAKE is automatically provided by Lima from {{.Param.flake}}
TARGET_FLAKE="${PARAM_FLAKE}"

# Determine which Flake URI to use.
if [[ "${TARGET_FLAKE}" == "/"* ]] && [[ ! -d "${TARGET_FLAKE}" ]]; then
	echo "Local directory ${TARGET_FLAKE} not found, falling back to GitHub main branch."
	TARGET_FLAKE="github:kachick/dotfiles/main"
fi

echo "Applying home-manager using flake: ${TARGET_FLAKE}"
nix run "${TARGET_FLAKE}#home-manager" -- switch -b backup --show-trace --flake "${TARGET_FLAKE}#user@lima"
