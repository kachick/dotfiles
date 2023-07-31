#!/usr/bin/env bash

set -euo pipefail

nix shell github:bobvanderlinden/nixpkgs-ruby#'"ruby-3.2"' --command ruby "$@"
