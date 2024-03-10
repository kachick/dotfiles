#!/bin/bash

set -euo pipefail

sandbox() {
	local -r container_id="$(podman run --detach --rm localhost/provisioned-systemd-home)"
	podman exec --user=user --workdir='/home/user' -it "$container_id" '/home/user/.nix-profile/bin/zsh'
	podman kill "$container_id"
}

sandbox
