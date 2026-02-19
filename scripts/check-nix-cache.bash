#!/usr/bin/env bash

# This script checks if a given Nix installable (package, home-manager config, etc.)
# is available in any of the configured substituters.
# It uses 'nix build --dry-run' to perform a robust, substituter-agnostic check.

set -euo pipefail

if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <installable> [check_tests]"
	exit 2
fi

INSTALLABLE=$1
CHECK_TESTS=${2:-false}

# Check if the primary installable needs a rebuild.
# If any actual store paths ending in ".drv" need to be built,
# it means the target is not available in any substituter.
# We ignore "nix-shell.drv" because it's always rebuilt even if dependencies are cached.
if nix build "$INSTALLABLE" --dry-run --extra-experimental-features 'nix-command flakes' 2>&1 |
	grep -o '/nix/store/[^ ]*\.drv' |
	grep -vE "nix-shell\.drv|inputDerivation-nix-shell\.drv" |
	grep -q "."; then
	# Rebuild required
	exit 1
fi

# Optionally check if passthru.tests also need a rebuild.
if [[ "$CHECK_TESTS" == "true" ]]; then
	if nix eval "$INSTALLABLE.passthru.tests" --extra-experimental-features 'nix-command flakes' > /dev/null 2>&1; then
		if nix build "$INSTALLABLE.passthru.tests" --dry-run --extra-experimental-features 'nix-command flakes' 2>&1 |
			grep -o '/nix/store/[^ ]*\.drv' |
			grep -q "."; then
			# Tests need rebuild
			exit 1
		fi
	fi
fi

# Everything is cached
exit 0
