#!/usr/bin/env -S bash

## Use Process Substitution for this script
# - https://www.gnu.org/software/bash/manual/html_node/Process-Substitution.html
# - https://qiita.com/takei-yuya@github/items/7afcb92cfe7e678b7f6d
#
# bad: cmd | bash -s - arg
# good: bash <(cmd) arg

set -euo pipefail

print_help() {
	cat <<'EOF'
Usage: sandbox.bash [OPTIONS]

Options:
  --local [IMAGE]     Run a local image (default: localhost/home:latest)
  --ghcr <TAG>        Pull and run ghcr.io/kachick/home:<TAG>
  --image <IMAGE>     Run a specific image directly
  --live              Mount the current dotfiles repo read-only at /workspace/dotfiles
  -h, --help          Show this help message
EOF
}

sandbox() {
	local image=""
	local mode="local"
	local live=false

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--ghcr)
			if [[ -z "${2:-}" ]]; then
				echo "Error: --ghcr requires a tag argument" >&2
				exit 1
			fi
			mode="ghcr"
			image="$2"
			shift 2
			;;
		--image)
			if [[ -z "${2:-}" ]]; then
				echo "Error: --image requires an image argument" >&2
				exit 1
			fi
			mode="image"
			image="$2"
			shift 2
			;;
		--local)
			mode="local"
			if [[ -n "${2:-}" && "${2:-}" != --* ]]; then
				image="$2"
				shift 2
			else
				shift 1
			fi
			;;
		--live)
			live=true
			shift 1
			;;
		-h | --help)
			print_help
			exit 0
			;;
		*)
			echo "Error: Unknown option '$1'" >&2
			print_help >&2
			exit 1
			;;
		esac
	done

	local target_image
	if [[ "$mode" == "ghcr" ]]; then
		cat <<'EOF'
============
if you encounter errors with ghcr.io images, may need following setup

# https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
export CR_PAT=YOUR_GHCR_TOKEN
echo $CR_PAT | podman login ghcr.io -u YOUR_USERNAME --password-stdin
============
EOF
		target_image="$(podman pull "ghcr.io/kachick/home:${image}")"
	elif [[ -n "$image" ]]; then
		target_image="$image"
	else
		target_image="localhost/home:latest"
	fi

	local -a run_args=(--detach --rm)
	if [[ "$live" == true ]]; then
		local repo_root
		repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
		run_args+=(--volume "${repo_root}:/workspace/dotfiles:ro")
		# Mask local .env so host tokens or settings are not exposed to the container
		if [[ -f "${repo_root}/.env" ]]; then
			run_args+=(--volume "/dev/null:/workspace/dotfiles/.env:ro")
		fi
		cat <<EOF
Live mount enabled: ${repo_root} -> /workspace/dotfiles (read-only)
Apply changes inside the container with:
  nix run /workspace/dotfiles#home-manager -- switch --flake /workspace/dotfiles#visitor@container
EOF
	fi

	local -r container_id="$(podman run "${run_args[@]}" "${target_image}")"
	# shellcheck disable=SC2064
	trap "podman kill '${container_id}'" EXIT ERR
	sleep 1 # Wait for the systemd to be ready
	podman exec --user=visitor --workdir='/home/visitor' --env=TERM --interactive --tty "${container_id}" '/home/visitor/.nix-profile/bin/bash' --login
}

sandbox "$@"
