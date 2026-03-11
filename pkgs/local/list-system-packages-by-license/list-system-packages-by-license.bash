#!/usr/bin/env bash
set -euo pipefail

show_help() {
	cat <<EOF
Usage: list-system-packages-by-license <hostname> <mode>

Modes:
  [Evaluation Only - Fast, no store required]
  --eval-allowed-unfree-package-names
      Lists the names from config.nixpkgs.allowedUnfreePackageNames.

  --eval-allowed-unfree-package-outpaths
      Lists the exact Nix store paths for the allowed unfree packages.

  [Realization Required - Requires system to be built]
  --filter-free-licensed-closure-from-build-result
      Retrieves all store paths in the system's closure and filters out unfree ones.
      This mode REQUIRES that the system top-level has already been built and is present in the store.

  [Unified]
  --json
      Outputs both evaluation and (if available) realization data in JSON format.
EOF
}

if [[ $# -lt 2 ]]; then
	show_help
	exit 1
fi

hostname="$1"
mode="$2"

# 1. Evaluation phase (Always runs, fast)
# Resolve allowed unfree names and their paths from config.
# shellcheck disable=SC2016
unfree_json=$(nix eval ".#nixosConfigurations.${hostname}" --json --apply 'host:
  let
    names = host.config.nixpkgs.allowedUnfreePackageNames;
    pkgs = host.pkgs;
    findPkg = name:
      if pkgs ? ${name} then pkgs.${name}
      else if pkgs.local ? ${name} then pkgs.local.${name}
      else null;
    unfreePkgs = builtins.filter (p: p != null) (builtins.map findPkg names);
  in
  builtins.map (p: {
    inherit (p) name;
    paths = builtins.map (outputName: p.${outputName}.outPath) p.outputs;
  }) unfreePkgs')

# 2. Realization phase (Conditional, requires store paths)
all_paths=""
if [[ "$mode" == "--filter-free-licensed-closure-from-build-result" || "$mode" == "--json" ]]; then
	# Only attempt path-info if we really need it or requested JSON.
	# Use --no-substitute to avoid long downloads or timeouts if triggered manually on missing paths.
	all_paths=$(nix path-info --no-substitute -r ".#nixosConfigurations.${hostname}.config.system.build.toplevel" 2>/dev/null || echo "")
fi

case "$mode" in
--eval-allowed-unfree-package-names)
	echo "$unfree_json" | jq -r '.[].name'
	;;
--eval-allowed-unfree-package-outpaths)
	echo "$unfree_json" | jq -r '.[].paths[]'
	;;
--filter-free-licensed-closure-from-build-result)
	if [[ -z "$all_paths" ]]; then
		echo "Error: System closure not found in store for hostname '${hostname}'." >&2
		echo "This mode requires the system to be built first." >&2
		echo "Try running: nix build .#nixosConfigurations.${hostname}.config.system.build.toplevel" >&2
		exit 1
	fi
	unfree_paths=$(echo "$unfree_json" | jq -r '.[].paths[]')
	if [[ -n "$unfree_paths" ]]; then
		echo "$all_paths" | grep -F -v -f <(echo "$unfree_paths")
	else
		echo "$all_paths"
	fi
	;;
--json)
	jq -n --argjson unfree "$unfree_json" --arg closure "$all_paths" \
		'{ unfree: $unfree, closure: ($closure | split("\n") | map(select(length > 0))) }'
	;;
*)
	echo "Error: Unknown mode '$mode'" >&2
	show_help
	exit 1
	;;
esac
