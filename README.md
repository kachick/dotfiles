# dotfiles

[![Home Status](https://github.com/kachick/dotfiles/actions/workflows/ci-home.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-home.yml?query=branch%3Amain+)
[![Home Status](https://github.com/kachick/dotfiles/actions/workflows/windows.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/windows.yml?query=branch%3Amain+)
[![Nix Status](https://github.com/kachick/dotfiles/actions/workflows/ci-nix.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-nix.yml?query=branch%3Amain+)
[![CI - Go Status](https://github.com/kachick/dotfiles/actions/workflows/ci-go.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-go.yml?query=branch%3Amain+)
[![Container Status](https://github.com/kachick/dotfiles/actions/workflows/container.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/container.yml?query=branch%3Amain+)

Personal dotfiles that can be placed in the public repository\
Also known as [盆栽(bonsai)](https://en.wikipedia.org/wiki/Bonsai) 🌳

## Installation - Linux(Ubuntu), Darwin

1. Install some dependencies without nix
   ```bash
   # "shadow" in nixpkg is not enough for podman - https://github.com/NixOS/nixpkgs/issues/138423
   sudo apt-get install uidmap
   ```
1. Install [Nix](https://nixos.org/) package manager with [DeterminateSystems/nix-installer](https://github.com/DeterminateSystems/nix-installer).
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```
1. Make sure there is a nix directory that is used in the home-manager.\
   This is a workaround, See [the thread](https://www.reddit.com/r/Nix/comments/1443k3o/comment/jr9ht5g/?utm_source=reddit&utm_medium=web2x&context=3) for detail
   ```bash
   mkdir -p ~/.local/state/nix/profiles
   ```
1. Restart current shell to load Nix as a PATH
   ```bash
   bash
   ```
1. Install [home-manager](https://github.com/nix-community/home-manager) and dotfiles
   ```bash
   nix run 'github:kachick/dotfiles#home-manager' -- switch -b backup --flake 'github:kachick/dotfiles#kachick'
   ```
1. If you are developing this repository, the simple reactivation is as follows.
   ```bash
   makers apply
   ```

### I'm a visitor to this repository. How can I try this dotfiles?

This repository is for my personal use.\
I don't care and make no guarantees for your trouble. But I'm using the following steps for another login.

1. [flake.nix](flake.nix): Custom `user = home-manager.lib.homeManagerConfiguration {...};` section
1. Replace one of above steps, home-manager section as below

```diff
-nix run 'github:kachick/dotfiles#home-manager' -- switch -b backup --flake 'github:kachick/dotfiles#kachick'
+nix run 'github:kachick/dotfiles#home-manager' -- switch -b backup --flake 'github:kachick/dotfiles#user'
```

You can test the [container](Containerfile) with your podman/docker/nerdctl as follows.

```bash
podman run -it ghcr.io/kachick/home:latest
```

## Installation - Windows

Read [the tips](config/windows/README.md)

## If you encounter errors

Check both the [CI](.github/workflows/ci-home.yml) and the [wiki](https://github.com/kachick/dotfiles/wiki) and update them.
