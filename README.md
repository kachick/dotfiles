# dotfiles

[![Linter Status](https://github.com/kachick/dotfiles/actions/workflows/lint.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/lint.yml?query=branch%3Amain+)
[![Nix Status](https://github.com/kachick/dotfiles/actions/workflows/ci-nix.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-nix.yml?query=branch%3Amain+)

Personal dotfiles that can be placed in the public repository

Also known as [盆栽(bonsai)](https://en.wikipedia.org/wiki/Bonsai) 🌳

## Development

1. Install [Nix](https://nixos.org/) package manager
1. Run `nix-shell`. (`nix-shell --command 'zsh'` and `direnv allow` may not work if you have not completed all the installation steps.)
1. `makers setup`

## Installation

1. Do `Development` steps
1. Install [nix-community/home-manager](https://github.com/nix-community/home-manager)
1. Set `XDG_*` into current env. `. ./home/.bashrc`
1. Make sure `$XDG_CONFIG_HOME/home-manager/home.nix` does not exists. If not, check the content and remove
1. Run `go run ./cmd/mksym --linker path-from --linked path-to` if needed
1. `home-manager switch`
1. (optional) Install [jdxcode/rtx](https://github.com/jdxcode/rtx) to manage subdivided versions

## I don't know ??? - I have just installed OS, I am 🚼

If you backed to 🚼 from some reasons, read [wiki](https://github.com/kachick/dotfiles/wiki)
