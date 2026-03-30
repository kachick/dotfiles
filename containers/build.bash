#!/usr/bin/env -S bash

set -euxo pipefail

# Fallback to defaults if not set (e.g., local build)
# The image name in GHCR
readonly IMAGE_NAME="${IMAGE_NAME:-home}"
# The base URL for GHCR
readonly GHCR_BASE="${GHCR_BASE:-ghcr.io/kachick}"

# The latest provisioned image used for incremental builds
readonly PREV_IMAGE="${GHCR_BASE}/${IMAGE_NAME}:latest"

build() {
	local build_args=()

	# Try to use the previous image as a base for incremental build unless forced to full rebuild
	if [[ "${FORCE_FULL_REBUILD:-false}" != "true" ]]; then
		if podman pull "${PREV_IMAGE}"; then
			build_args=("--build-arg" "BASE_IMAGE=${PREV_IMAGE}")
			echo "Using previous image as base for incremental build: ${PREV_IMAGE}"
		else
			echo "Previous image not found. Falling back to the default in Containerfile."
		fi
	else
		echo "Forcing full rebuild using the default in Containerfile."
	fi

	podman build \
		"${build_args[@]}" \
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
