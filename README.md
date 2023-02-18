# public_dotfiles

[![Build Status](https://github.com/kachick/public_dotfiles/actions/workflows/lint.yml/badge.svg?branch=main)](https://github.com/kachick/public_dotfiles/actions/workflows/lint.yml?query=branch%3Amain+)

Personal dotfiles. :see_no_evil: Excluded sensitive information like command histories :yum:.

## Development

1. Install [Nix](https://nixos.org/) package manager
2. Run `nix-shell` or `nix-shell --command 'zsh'`
3. `makers setup`

## Installation

1. Install [nix-community/home-manager](https://github.com/nix-community/home-manager)
2. `cp ./.config/nixpkgs/home.nix ~/.config/nixpkgs && home-manager switch`

## Dependent tools

- [Nix, the purely functional package manager](https://github.com/NixOS/nix)
- [Nix Packages collection](https://github.com/NixOS/nixpkgs)
- [nix-community/home-manager](https://github.com/nix-community/home-manager)
- [zsh-users/zsh](https://github.com/zsh-users/zsh)
- [zsh-users/zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)
- [sorin-ionescu/prezto](https://github.com/sorin-ionescu/prezto)

## Note

- [About Nix](https://github.com/kachick/times_kachick/issues/204)
- [Notes for login shell issues](https://github.com/kachick/public_dotfiles/wiki/Notes-for-login-shell-issues)
- Do not manage [Rust](https://github.com/rust-lang/rust) with asdf. Prefer [official steps and rustup](https://www.rust-lang.org/ja/tools/install).
- [Which shell? zsh? bash? fish? nushell?](https://github.com/kachick/times_kachick/issues/184)
- [docker => singularity](https://github.com/kachick/times_kachick/issues/186)
- [Note of Pop! OS](https://github.com/kachick/times_kachick/issues/174)
- [Colorize vscode](https://github.com/kachick/times_kachick/issues/93)
