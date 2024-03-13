#!/bin/bash

set -euxo pipefail

cat <<'EOF'
============
if you encounter errors, may need following setup

# https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
export export CR_PAT=YOUR_GHCR_TOKEN
echo $CR_PAT | podman login ghcr.io -u YOUR_USERNAME --password-stdin
============
EOF

sandbox() {
	local -r tag="$1"
	local -r container_id="$(podman run --detach --rm "ghcr.io/kachick/home:${tag}")"
	sleep 1 # Wait for the systemd to be ready
	podman exec --user=user --workdir='/home/user' -it "$container_id" '/home/user/.nix-profile/bin/zsh'
	podman kill "$container_id"
}

sandbox "$1"
