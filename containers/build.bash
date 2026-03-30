#!/usr/bin/env -S bash

set -euxo pipefail

# The latest provisioned image
readonly PREV_IMAGE="ghcr.io/kachick/dotfiles/provisioned-systemd-home:latest"
# The clean base image
readonly CLEAN_BASE="ghcr.io/kachick/ubuntu-24.04-nix-systemd:latest@sha256:b1e529b73dfaf44935127bd3902fb91e9d761b7f750632f6a704ff0ee23564ed"

build() {
	local base_image="${CLEAN_BASE}"

	# Try to use the previous image as a base for incremental build unless forced to full rebuild
	if [[ "${FORCE_FULL_REBUILD:-false}" != "true" ]]; then
		if podman pull "${PREV_IMAGE}"; then
			base_image="${PREV_IMAGE}"
			echo "Using previous image as base for incremental build: ${base_image}"
		else
			echo "Previous image not found. Falling back to full build."
		fi
	else
		echo "Forcing full rebuild from clean base."
	fi

	podman build \
		--build-arg "BASE_IMAGE=${base_image}" \
		--tag nix-systemd \
		--file containers/Containerfile .

	local -r container_id="$(podman run --detach --rm localhost/nix-systemd:latest)"
	# shellcheck disable=SC2064
	trap "podman kill '$container_id'" EXIT ERR
	sleep 1 # Wait for the systemd to be ready
	podman exec --user=root -it "$container_id" nix run '/provisioner/dotfiles#apply-system'
	podman exec --user=user -it "$container_id" /provisioner/needs_systemd.bash
	podman exec --user=root -it "$container_id" rm -rf /provisioner
	podman commit "$container_id" provisioned-systemd-home
}

build
