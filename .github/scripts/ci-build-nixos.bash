#!/usr/bin/env bash
set -euo pipefail

HOST="${1}"
LOG_FILE="/tmp/nix-stderr-${HOST}"

echo "Building NixOS configuration: ${HOST}"
nix build ".#nixosConfigurations.${HOST}.config.system.build.toplevel" --no-link --show-trace 2> >(tee "${LOG_FILE}" >&2)

if grep -i "warning:" "${LOG_FILE}"; then
	echo "❌ Nix evaluation warnings detected!"
	exit 1
fi
