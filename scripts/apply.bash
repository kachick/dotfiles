#!/usr/bin/env bash

set -euxo pipefail

if [ -f '/etc/NIXOS' ]; then
	sudo nixos-rebuild switch --flake ".#$(hostname)" --show-trace
fi

# Using hostname simplify flake option, see https://discourse.nixos.org/t/get-hostname-in-home-manager-flake-for-host-dependent-user-configs/18859/2
# However prefer to use special ENV here for my current use. It is useful if sharing same config for similar env but on different devices
nix run '.#home-manager' -- switch -b backup --show-trace --flake ".#${USER}@${HM_HOST_SLUG}"
