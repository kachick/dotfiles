# public_dotfiles

[![Build Status](https://github.com/kachick/public_dotfiles/actions/workflows/lint.yml/badge.svg?branch=main)](https://github.com/kachick/public_dotfiles/actions/workflows/lint.yml?query=branch%3Amain+)

Personal dotfiles. :see_no_evil: Excluded sensitive information like command histories :yum:.

## Installation

1. "[Pop! OS](https://github.com/system76/docs)([Ubuntu](https://github.com/ubuntu))" or "Ubuntu on [WSL2](https://github.com/microsoft/WSL2-Linux-Kernel) or [lima](https://github.com/lima-vm/lima)"
1. [`bootstrap.sh`](scripts/bootstrap.sh)

See [.zshrc](.config/.zshrc) for overview and create symlinks to my $HOME
And do below

1. `zprezto-update`
1. Sync vscode config with cloud account

## Dependent tools

- [Nix, the purely functional package manager](https://github.com/NixOS/nix)
- [Nix Packages collection](https://github.com/NixOS/nixpkgs)
- [Homebrew/brew](https://github.com/Homebrew/brew)
- [asdf-vm/asdf](https://github.com/asdf-vm/asdf)
- [zsh-users/zsh](https://github.com/zsh-users/zsh)
- [zsh-users/zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)
- [sorin-ionescu/prezto](https://github.com/sorin-ionescu/prezto)
- [nushell/nushell](https://github.com/nushell/nushell)
- [git/git](https://github.com/git/git)
- [microsoft/vscode](https://github.com/microsoft/vscode)
- [ruby/irb](https://github.com/ruby/irb)
- [kachick/irb-power_assert](https://github.com/kachick/irb-power_assert)
- [gnachman/iTerm2](https://github.com/gnachman/iTerm2)

## Note

- Do not manage [Rust](https://github.com/rust-lang/rust) with asdf. Prefer [official steps and rustup](https://www.rust-lang.org/ja/tools/install).
- [Which shell? zsh? bash? fish? nushell?](https://github.com/kachick/times_kachick/issues/184)
- [docker => singularity](https://github.com/kachick/times_kachick/issues/186)
- [Note of Pop! OS](https://github.com/kachick/times_kachick/issues/174)
- [Colorize](https://github.com/kachick/times_kachick/issues/93)

## Terminal

One of terminal. (Or use vscode terminal.)

- Windows - Windows Terminal
- Mac OS - iTerm2 or [tabby](https://github.com/Eugeny/tabby)
- Linux - tabby
