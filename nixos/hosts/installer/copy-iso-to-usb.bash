#!/usr/bin/env -S bash

set -euo pipefail

if [[ $# -gt 1 ]]; then
	echo "Usage: $0 [destination-dir]" >&2
	exit 1
fi

dest_dir="${1:-/run/media/${USER}/MultiOS-USB/ISOs}"

# Check the USB mount before spending minutes building the ISO.
if [[ ! -d "${dest_dir}" || ! -w "${dest_dir}" ]]; then
	echo "Destination directory is missing or not writable: ${dest_dir}" >&2
	exit 1
fi

# Build on local storage with --no-link instead of targeting USB directly, so
# USB flash only takes one sequential copy and the ISO path can be deleted right away.
iso_dir="$(nix build ".#nixosConfigurations.installer.config.system.build.isoImage" --no-link --print-out-paths --show-trace)"

shopt -s nullglob
iso_files=("${iso_dir}"/iso/*.iso)
shopt -u nullglob

if [[ ${#iso_files[@]} -ne 1 ]]; then
	echo "Expected 1 ISO under ${iso_dir}/iso, found ${#iso_files[@]}" >&2
	exit 1
fi

cp --verbose "${iso_files[0]}" "${dest_dir}/"
sync
nix store delete "${iso_dir}"
