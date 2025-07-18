#!/usr/bin/env bash

set -euxo pipefail

if [ -f '/etc/NIXOS' ]; then
	# Prefer `build` rather than `test` and `dry-reactivate` for the speed and not requiring root permissions
	nixos-rebuild build --flake ".#$(hostname)" --show-trace
else
	# -n = dry-run
	nix run '.#home-manager' -- switch -n -b backup --show-trace --flake ".#${USER}@${HM_HOST_SLUG}"
fi
