#!/usr/bin/env bash

set -euxo pipefail

make_symlink() {
  local create_in="$1"
  local source_path="$2"

  # https://linuxjm.osdn.jp/info/GNU_coreutils/coreutils-ja_86.html
  ln --symbolic --verbose --backup --relative --no-dereference --target-directory="$create_in" "$source_path"
}

paths_to_root() {
  cat <<'EOD'
.stack
.default-gems
.irbrc
.zshenv
.aliases.sh
.bashrc
EOD
}

make_symlinks() {
  # Can't reuse shell functions in passing to xargs... :<
  paths_to_root | xargs -I{} ln --symbolic --verbose --backup --relative --no-dereference --target-directory="$HOME/.config" "./.config/{}"

  mkdir -p "$HOME/.stack"
  make_symlink "$HOME/.stack" ./.config/.stack/config.yaml
}

make_symlinks
