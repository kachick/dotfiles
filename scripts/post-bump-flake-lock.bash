#!/usr/bin/env bash

set -euo pipefail

nix run .#flake-edit -- --non-interactive follow --transitive
nix fmt flake.nix
nix flake lock
nix run .#bump_gomod -- .
