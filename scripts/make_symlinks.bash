#!/usr/bin/env bash

set -euxo pipefail

make_symlink() {
  local create_in="$1"
  local source_path="$2"

  # https://linuxjm.osdn.jp/info/GNU_coreutils/coreutils-ja_86.html
  ln --symbolic --verbose --backup --relative --no-dereference --target-directory="$create_in" "$source_path"
}

make_symlinks() {
  local dotfile

  for dotfile in ./.config/.??*; do
    make_symlink "$HOME" "$dotfile"
  done

  make_symlink "$HOME/.config" ./.config/starship.toml
}

make_symlinks
