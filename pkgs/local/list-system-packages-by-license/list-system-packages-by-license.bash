#!/usr/bin/env bash
set -euo pipefail

# Usage: list-system-packages-by-license <hostname> <mode>
# Modes: --free, --unfree, --json

if [[ $# -lt 2 ]]; then
  echo "Usage: list-system-packages-by-license <hostname> <mode: --free|--unfree|--json>" >&2
  exit 1
fi

hostname="$1"
mode="$2"

# Retrieve system packages categorized by license for the given hostname configuration.
# Note: Flake path is assumed to be current directory.
# Returns JSON object with "free" (outPaths for cache) and "unfree" (names for logging).
results=$(nix eval ".#nixosConfigurations.${hostname}.config.environment.systemPackages" --json --apply 'ps: let 
  isFree = p: let 
    lic = p.meta.license or {}; 
  in if builtins.isList lic then 
       builtins.all (l: l.free or true) lic 
     else 
       lic.free or true;
  # Split packages into free and unfree groups
  groups = builtins.groupBy (p: if isFree p then "free" else "unfree") ps;
in 
  {
    free = builtins.map (p: p.outPath) (groups.free or []);
    unfree = builtins.map (p: p.name) (groups.unfree or []);
  }')

case "$mode" in
  --free)
    echo "$results" | jq -r ".free[]"
    ;;
  --unfree)
    echo "$results" | jq -r ".unfree[]"
    ;;
  --json)
    echo "$results"
    ;;
  *)
    echo "Error: Unknown mode '$mode'. Use --free, --unfree, or --json." >&2
    exit 1
    ;;
esac
