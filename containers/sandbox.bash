#!/usr/bin/env -S bash

## Use Process Substitution for this script
# - https://www.gnu.org/software/bash/manual/html_node/Process-Substitution.html
# - https://qiita.com/takei-yuya@github/items/7afcb92cfe7e678b7f6d
#
# bad: cmd | bash -s - arg
# good: bash <(cmd) arg

set -euo pipefail

sandbox() {
	local -r tag="${1:-}"
	local image
	if [[ -n "${tag}" ]]; then
		cat <<'EOF'
============
if you encounter errors with ghcr.io images, may need following setup

# https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
export CR_PAT=YOUR_GHCR_TOKEN
echo $CR_PAT | podman login ghcr.io -u YOUR_USERNAME --password-stdin
============
EOF
		image="$(podman pull "ghcr.io/kachick/home:${tag}")"
	else
		image="localhost/provisioned-systemd-home"
	fi

	local -r container_id="$(podman run --detach --rm "${image}")"
	# shellcheck disable=SC2064
	trap "podman kill '${container_id}'" EXIT ERR
	sleep 1 # Wait for the systemd to be ready
	podman exec --user=user --workdir='/home/user' --env=TERM --interactive --tty "${container_id}" '/home/user/.nix-profile/bin/bash' --login
}

sandbox "${1:-}"
