#!/usr/bin/env bash

set -euxo pipefail

shopt -s globstar

# https://github.com/kachick/dotfiles/issues/149
install_latest_sheldon() {
	mkdir -p "$XDG_DATA_HOME/sheldon/bin"
	# https://github.com/rossmacarthur/sheldon/blob/e989c2f1799988104ecf2dff4e5907d54fc1d693/README.md#pre-built-binaries
	# Depending external resource without any hash ... :<
	curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | bash -s -- --repo rossmacarthur/sheldon --to "$XDG_DATA_HOME/sheldon/bin"
}

# Do NOT use (( $+commands[sheldon] )) here. It made 1.5x slower zsh execution :<
if ! type 'sheldon' >/dev/null; then
	install_latest_sheldon
fi
