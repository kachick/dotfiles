#!/usr/bin/env bash

set -euxo pipefail

shopt -s globstar

# fixing typo is a fmt ...?
typos . .github .config .vscode --write-changes

dprint fmt
