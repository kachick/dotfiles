#!/bin/bash

set -euxo pipefail

build() {
	podman build --tag nix-systemd --file containers/Containerfile .
	podman run --rm localhost/nix-systemd:latest &
	sleep 1
	local -r container_name="$(podman ps --sort=created --format '{{.Names}}' | tail -1)"
	[ -n "$container_name" ]
	podman exec --user=user -it "$container_name" /provisioner/needs_systemd.bash
	podman exec --user=root -it "$container_name" rm -rf /provisioner/cleanup.bash
	podman commit "$container_name" provisioned-systemd-home
	podman kill "$container_name"
}

build
