# dotfiles

[![Home Status](https://github.com/kachick/dotfiles/actions/workflows/ci-home.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-home.yml?query=branch%3Amain+)
[![Nix Status](https://github.com/kachick/dotfiles/actions/workflows/ci-nix.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-nix.yml?query=branch%3Amain+)
[![CI - Go Status](https://github.com/kachick/dotfiles/actions/workflows/ci-go.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-go.yml?query=branch%3Amain+)

Personal dotfiles that can be placed in the public repository\
Also known as [盆栽(bonsai)](https://en.wikipedia.org/wiki/Bonsai) 🌳

## Installation - Linux, Darwin

1. Install [Nix](https://nixos.org/) package manager with [DeterminateSystems/nix-installer](https://github.com/DeterminateSystems/nix-installer).
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```
1. Make sure there is a nix directory that is used in the home-manager.\
   This is a workaround, See [the thread](https://www.reddit.com/r/Nix/comments/1443k3o/comment/jr9ht5g/?utm_source=reddit&utm_medium=web2x&context=3) for detail
   ```bash
   mkdir -p ~/.local/state/nix/profiles
   ```
1. Install [home-manager](https://github.com/nix-community/home-manager) and dotfiles
   ```bash
   nix run 'github:kachick/dotfiles#home-manager' -- switch -b backup --flake 'github:kachick/dotfiles#kachick'
   ```
1. Make shells installed by nix into a login shell
   ```bash
   nix run 'github:kachick/dotfiles#sudo_enable_nix_login_shells'
   ```
1. If you have any problems with the installation steps, check both the [CI](.github/workflows/ci-home.yml) and the [wiki](https://github.com/kachick/dotfiles/wiki) and update them.
1. If you are developing this repository, the simple reactivation is as follows.
   ```bash
   makers apply
   ```

## Installation - Windows

Read [windows steps and tips](windows.md)
test
test
test
test
test in fish
