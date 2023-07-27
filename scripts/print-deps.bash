#!/usr/bin/env bash

set -euxo pipefail

shopt -s globstar

makers --version
nix --version
dprint --version
shellcheck --version
shfmt --version
gitleaks version
fd --version
typos --version
chezmoi --version

# Returns NON 0, why...? :<
#  "nixpkgs-fmt --version",
