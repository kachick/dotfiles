#!/usr/bin/env bash

set -euxo pipefail

# https://linuxjm.osdn.jp/info/GNU_coreutils/coreutils-ja_86.html
ln --symbolic --verbose --backup --relative --no-dereference --target-directory="$1" "$2"
