#!/usr/bin/env bash

set -euxo pipefail

if [ -f '/etc/NIXOS' ]; then
	if [ "$#" -gt 1 ]; then
		echo "Usage: $0 [host]" >&2
		exit 1
	fi
	host="${1:-$(hostname)}"
	# Prefer `build` rather than `test` and `dry-reactivate` for the speed and not requiring root permissions
	nixos-rebuild build --flake ".#${host}" --show-trace
else
	if [ "$#" -ne 1 ]; then
		echo "Usage: $0 <host-slug>" >&2
		exit 1
	fi
	# -n = dry-run
	nix run '.#home-manager' -- switch -n -b backup --show-trace --flake ".#${USER}@$1"
fi
