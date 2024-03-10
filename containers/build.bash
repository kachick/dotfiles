#!/bin/bash

set -euxo pipefail

build() {
	podman build --tag nix-systemd --file containers/Containerfile .
	local -r container_id="$(podman run --detach --rm localhost/nix-systemd:latest)"
	podman exec --user=user -it "$container_id" /provisioner/needs_systemd.bash
	podman exec --user=root -it "$container_id" rm -rf /provisioner/cleanup.bash
	podman commit "$container_id" provisioned-systemd-home
	podman kill "$container_id"
}

build
