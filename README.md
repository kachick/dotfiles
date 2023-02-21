# dotfiles

[![Linter Status](https://github.com/kachick/dotfiles/actions/workflows/lint.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/lint.yml?query=branch%3Amain+)
[![Development Environment Status](https://github.com/kachick/dotfiles/actions/workflows/ci-dev.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-dev.yml?query=branch%3Amain+)

Personal dotfiles. :see_no_evil: Excluded sensitive information like command histories :yum:.

## Development

1. Install [Nix](https://nixos.org/) package manager
2. Run `nix-shell` or `nix-shell --command 'zsh'`
3. `makers setup`

## Installation

1. Install [nix-community/home-manager](https://github.com/nix-community/home-manager)
2. `./scripts/make_symlinks.bash`
3. `home-manager switch`
4. (optional) Install [jdxcode/rtx](https://github.com/jdxcode/rtx) to manage subdivided versions

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
- [Colorize vscode](https://github.com/kachick/times_kachick/issues/93)
