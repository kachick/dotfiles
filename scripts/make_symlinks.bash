#!/usr/bin/env bash

set -euxo pipefail

# https://stackoverflow.com/a/24112741/1212807
parent_path=$(
  cd "$(dirname "${BASH_SOURCE[0]}")"
  pwd -P
)

fd --hidden --type file --max-depth 1 '.' ./home | xargs -I{} "$parent_path/make_symlink.bash" "$HOME" '{}'
# TODO: Update in #142
"$parent_path/make_symlink.bash" "$HOME/.stack" './home/.stack/config.yaml'
