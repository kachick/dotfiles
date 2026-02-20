#!/bin/bash

# This script is automatically executed by Lima during provisioning as root (mode: system).
# See: https://github.com/lima-vm/lima/blob/v2.0.3/templates/default.yaml#L608-L614

set -eux -o pipefail

# 1. Install Nix (Multi-user) and enable flakes with binary caches
# Following README Ubuntu instructions carefully.
if ! command -v nix >/dev/null 2>&1; then
	extra_conf_path="$(mktemp --suffix=.extra.nix.conf)"
	{
		echo 'experimental-features = nix-command flakes'
		# 'user' is the name defined in the 'user' block of this YAML
		echo "trusted-users = root $LIMA_CID_USER @wheel"

		# Add binary caches from flake.nix to speed up provisioning
		echo "extra-substituters = https://kachick-dotfiles.cachix.org https://cache.nixos.org"
		echo "extra-trusted-public-keys = kachick-dotfiles.cachix.org-1:XhiP3JOkqNFGludaN+/send30shcrn1UMDeRL9XttkI= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
	} >>"$extra_conf_path"

	sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon --yes --nix-extra-conf-file "$extra_conf_path"
fi

# Force Nix profile loading for non-interactive shells in Ubuntu
if ! grep -q "nix-daemon.sh" /etc/bash.bashrc; then
	tee -a /etc/bash.bashrc <<'EOF'
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
EOF
fi

# 2. Apply home-manager
# Running as the user who is being provisioned.
sudo -u "$LIMA_CID_USER" -i bash -eux <<'EOF'
    # Step 3 in README Ubuntu section
    mkdir -p ~/.local/state/nix/profiles

    DOTFILES_DIR="$HOME/repos/github.com/kachick/dotfiles"
    if [ ! -d "$DOTFILES_DIR" ]; then
        echo "Dotfiles directory not found at $DOTFILES_DIR. Ensure it is mounted."
        exit 1
    fi

    cd "$DOTFILES_DIR"
    # Apply home-manager configuration for "user@lima" (or kachick@lima)
    # Using 'nix run' as recommended in README for the first time.
    # Since we changed to 'user@lima' previously, let's use it.
    nix run '.#home-manager' -- switch -b backup --show-trace --flake ".#user@lima"
EOF
