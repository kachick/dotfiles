#!/usr/bin/env -S bash

set -euo pipefail

print_help() {
	cat <<'EOF'
Usage: test.bash [OPTIONS] [IMAGE]

Options:
  --local [IMAGE]     Test a local image (default: localhost/provisioned-systemd-home)
  --ghcr <TAG>        Test ghcr.io/kachick/home:<TAG>
  --image <IMAGE>     Test a specific image directly
  -h, --help          Show this help message
EOF
}

test_container() {
	local image="localhost/provisioned-systemd-home"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--ghcr)
			if [[ -z "${2:-}" ]]; then
				echo "Error: --ghcr requires a tag argument" >&2
				exit 1
			fi
			image="ghcr.io/kachick/home:$2"
			shift 2
			;;
		--image)
			if [[ -z "${2:-}" ]]; then
				echo "Error: --image requires an image argument" >&2
				exit 1
			fi
			image="$2"
			shift 2
			;;
		--local)
			if [[ -n "${2:-}" && "${2:-}" != --* ]]; then
				image="$2"
				shift 2
			else
				image="localhost/provisioned-systemd-home"
				shift 1
			fi
			;;
		-h | --help)
			print_help
			exit 0
			;;
		*)
			image="$1"
			shift 1
			;;
		esac
	done

	echo "==> Testing container image: ${image}"

	local -r container_id="$(podman run --detach --rm "${image}")"
	# shellcheck disable=SC2064
	trap "podman kill '${container_id}'" EXIT ERR
	sleep 1 # Wait for systemd to be ready

	echo "==> [1/3] Checking subprocess PATH resolution for Nix profile tools"
	podman exec --user=user "${container_id}" which fd >/dev/null
	podman exec --user=user "${container_id}" sh -c 'which fd' >/dev/null
	echo "    PASS: 'fd' is found in PATH in direct and subshell invocations"

	echo "==> [2/3] Checking login shell startup for setlocale warnings"
	local shell_output
	shell_output="$(echo exit | podman exec --user=user --workdir=/home/user --env=TERM=xterm --interactive "${container_id}" /home/user/.nix-profile/bin/bash --login -i 2>&1)"
	if echo "${shell_output}" | grep -qi "cannot change locale"; then
		echo "    FAIL: setlocale warning detected in login shell startup:"
		echo "${shell_output}" | grep -i "cannot change locale"
		return 1
	fi
	echo "    PASS: No setlocale warnings in login shell startup"

	echo "==> [3/3] Checking locale environment values"
	local locale_output
	locale_output="$(podman exec --user=user --workdir=/home/user "${container_id}" /home/user/.nix-profile/bin/bash --login -c 'locale')"
	if ! echo "${locale_output}" | grep -q 'LANG=ja_JP.UTF-8'; then
		echo "    FAIL: Expected LANG=ja_JP.UTF-8, got:"
		echo "${locale_output}"
		return 1
	fi
	echo "    PASS: LANG=ja_JP.UTF-8 is correctly set"

	echo "==> All container smoke tests passed!"
}

test_container "$@"
