#!/usr/bin/env bash

set -euxo pipefail

shopt -s globstar

dprint check
shfmt --diff ./**/*.bash
shellcheck ./**/*.bash
nixpkgs-fmt --check ./**/*.nix
typos . .github .config .vscode
gitleaks detect
go vet ./...
