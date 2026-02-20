#!/bin/bash
set -eux -o pipefail

# 1. Install Nix (Multi-user) and enable flakes with binary caches
# Following README Ubuntu instructions.
if ! command -v nix >/dev/null 2>&1; then
	extra_conf_path="$(mktemp --suffix=.extra.nix.conf)"
	{
		echo 'experimental-features = nix-command flakes'
		echo "trusted-users = root user @wheel"
		# Initial bootstrap caches
		echo "extra-substituters = https://kachick-dotfiles.cachix.org https://cache.nixos.org"
		echo "extra-trusted-public-keys = kachick-dotfiles.cachix.org-1:XhiP3JOkqNFGludaN+/send30shcrn1UMDeRL9XttkI= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
	} >>"$extra_conf_path"

	# Provide $HOME for the installer, otherwise it fails in 'mode: system'
	export HOME=/root
	curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes --nix-extra-conf-file "$extra_conf_path"

	# After installation, we fetch the full synchronized list from the flake
	# using the provided param.flake URI.
	. /etc/profile.d/nix.sh
	# $PARAM_FLAKE is automatically provided by Lima from {{.Param.flake}}
	TARGET_FLAKE="${PARAM_FLAKE}"

	# Sync full cache list from constants
	SUBSTITUTERS=$(nix eval --raw "${TARGET_FLAKE}#lib.nixConfig.substituters" --apply 'builtins.concatStringsSep " "')
	KEYS=$(nix eval --raw "${TARGET_FLAKE}#lib.nixConfig.trusted-public-keys" --apply 'builtins.concatStringsSep " "')

	{
		echo "extra-substituters = ${SUBSTITUTERS}"
		echo "extra-trusted-public-keys = ${KEYS}"
	} | tee -a /etc/nix/nix.conf
	systemctl restart nix-daemon
fi

# Force Nix profile loading for non-interactive shells in Ubuntu.
if ! grep -q "nix-daemon.sh" /etc/bash.bashrc; then
	sed -i '1i if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; fi' /etc/bash.bashrc
fi
