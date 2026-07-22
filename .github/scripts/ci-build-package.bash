#!/usr/bin/env bash
set -euo pipefail

PNAME="${1}"
SYSTEM_ARCH="${2:-x86_64-linux}"
SKIP_TESTS="${3:-false}"
LOG_FILE="/tmp/nix-stderr-${PNAME}"

echo "Building package: ${PNAME} (${SYSTEM_ARCH})"
nix build ".#${PNAME}" --no-link --show-trace 2> >(tee "${LOG_FILE}" >&2)

if grep -i "warning:" "${LOG_FILE}"; then
	echo "❌ Nix evaluation warnings detected!"
	exit 1
fi

if [[ "${SKIP_TESTS}" == "true" ]]; then
	echo "Skipping tests for ${PNAME} as requested."
	exit 0
fi

if nix eval ".#${PNAME}.passthru.tests" >/dev/null 2>&1; then
	nix-build --attr "packages.${SYSTEM_ARCH}.${PNAME}.passthru.tests"
else
	echo "No passthru.tests found for ${PNAME}, skipping."
fi
