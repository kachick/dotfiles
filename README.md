# dotfiles

[![Linter Status](https://github.com/kachick/dotfiles/actions/workflows/lint.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/lint.yml?query=branch%3Amain+)
[![Development Environment Status](https://github.com/kachick/dotfiles/actions/workflows/ci-dev.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-dev.yml?query=branch%3Amain+)

Personal dotfiles that can be placed in the public repository

Also known as [盆栽(bonsai)](https://en.wikipedia.org/wiki/Bonsai) 🌳 :relaxed:\
⬆️ Do these lines and emoji look right to you? If not, check the fonts!

## I have just installed OS

If you backed to 🚼 from some reasons, See [Wiki](https://github.com/kachick/dotfiles/wiki) at first

## Development

1. Install [Nix](https://nixos.org/) package manager
2. Run `nix-shell`. (`nix-shell --command 'zsh'` might not work if you did not finish whole installation steps ever)
3. `makers setup`

## Installation

1. Do `Development` steps
1. Install [nix-community/home-manager](https://github.com/nix-community/home-manager)
1. Set `XDG_*` into current env. `. ./home/.bashrc`
1. Make sure `$XDG_CONFIG_HOME/home-manager/home.nix` does not exists. If not, check the content and remove
1. `./scripts/make_symlinks.bash`
1. `home-manager switch`
1. (optional) Install [jdxcode/rtx](https://github.com/jdxcode/rtx) to manage subdivided versions

## Dependent tools

- [Nix, the purely functional package manager](https://github.com/NixOS/nix)
- [Nix Packages collection](https://github.com/NixOS/nixpkgs)
- [nix-community/home-manager](https://github.com/nix-community/home-manager)

## Note

- [About Nix](https://github.com/kachick/times_kachick/issues/204)
- [Notes for login shell issues](https://github.com/kachick/dotfiles/wiki/Notes-for-login-shell-issues)
- [Which shell? zsh? bash? fish? nushell?](https://github.com/kachick/times_kachick/issues/184)
- [docker => singularity](https://github.com/kachick/times_kachick/issues/186)
- [Note of Pop! OS](https://github.com/kachick/times_kachick/issues/174)
- [Disable noisy beep](https://github.com/kachick/times_kachick/issues/214)
- [Colorize vscode](https://github.com/kachick/times_kachick/issues/93)
