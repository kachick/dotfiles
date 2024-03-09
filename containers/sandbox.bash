#!/bin/bash

set -euo pipefail

sandbox() {
	podman run --rm localhost/provisioned-systemd-home &
	sleep 1
	local -r container_name="$(podman ps --sort=created --format '{{.Names}}' | tail -1)"
	[ -n "$container_name" ]
	podman exec --user=user --workdir='/home/user' -it "$container_name" /home/user/.nix-profile/bin/zsh
	podman kill "$container_name"
}

sandbox
