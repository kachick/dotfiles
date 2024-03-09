#!/bin/bash

set -euo pipefail

cat <<'EOF'
============
if you encounter errors, may need following setup

# https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
export export CR_PAT=YOUR_GHCR_TOKEN
echo $CR_PAT | podman login ghcr.io -u YOUR_USERNAME --password-stdin
============
EOF

sandbox() {
	podman run --rm ghcr.io/kachick/home:latest &
	sleep 1
	container_name="$(podman ps --sort=created --format '{{.Names}}' | tail -1)"
	[ -n "$container_name" ]
	podman exec --user=user --workdir='/home/user' -it "$container_name" /home/user/.nix-profile/bin/zsh
	podman kill "$container_name"
}

sandbox
