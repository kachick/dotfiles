#!/bin/bash

set -euxo pipefail

build() {
	podman build --tag nix-systemd --file containers/Containerfile .
	local -r container_id="$(podman run --detach --rm localhost/nix-systemd:latest)"
	# shellcheck disable=SC2064
	trap "podman kill '$container_id'" EXIT ERR
	sleep 1 # Wait for the systemd to be ready
	podman exec --user=user -it "$container_id" /provisioner/needs_systemd.bash
	podman exec --user=root -it "$container_id" rm -rf /provisioner
	podman commit "$container_id" provisioned-systemd-home
}

build
