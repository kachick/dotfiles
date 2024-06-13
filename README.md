# dotfiles

[![Home Status](https://github.com/kachick/dotfiles/actions/workflows/ci-home.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-home.yml?query=branch%3Amain+)
[![Home Status](https://github.com/kachick/dotfiles/actions/workflows/windows.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/windows.yml?query=branch%3Amain+)
[![Nix Status](https://github.com/kachick/dotfiles/actions/workflows/ci-nix.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-nix.yml?query=branch%3Amain+)
[![CI - Go Status](https://github.com/kachick/dotfiles/actions/workflows/ci-go.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-go.yml?query=branch%3Amain+)
[![Container Status](https://github.com/kachick/dotfiles/actions/workflows/container.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/container.yml?query=branch%3Amain+)

Personal dotfiles that can be placed in the public repository\
Also known as [盆栽(bonsai)](https://en.wikipedia.org/wiki/Bonsai) 🌳

## For visitors

If you are using [Podman](https://podman.io/), you can test the pre-built [container-image](containers) as follows.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/kachick/dotfiles/main/containers/sandbox-with-ghcr.bash) latest
```

Or, you can directly use some commands with `nix run` without any installation steps.

```bash
nix run 'github:kachick/dotfiles#todo'
nix run 'github:kachick/dotfiles#bench_shells'
nix run 'github:kachick/dotfiles#git-delete-merged-branches'
nix run 'github:kachick/dotfiles#walk'
nix run 'github:kachick/dotfiles#prs'
```

## Linux(Ubuntu)

1. Install [Nix](https://nixos.org/) package manager with [DeterminateSystems/nix-installer](https://github.com/DeterminateSystems/nix-installer) to enable [Flakes](https://nixos.wiki/wiki/Flakes) by default.
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
1. Apply dotfiles for each use
   ```bash
   nix run 'github:kachick/dotfiles#home-manager' -- switch -b backup --flake 'github:kachick/dotfiles#user@linux'
   ```
   Candidates
   - `user@linux` # Used in container
   - `kachick@linux`

## NixOS

[Work in Progress](https://github.com/kachick/dotfiles/pull/576)

## macOS(Darwin)

Activate `kachick@macbook` as Linux

## Windows

After installing WSL2, you can activate home-manager with `kachick@wsl` as Linux.\
Read [Windows README](windows/README.md) and [CI](.github/workflows/windows.yml) for further detail.

## Note

If you are developing this repository, the simple reactivation is as follows.

```bash
makers apply user@linux
```

Using podman may require to install some dependencies without Nix

```bash
# "shadow" in nixpkg is not enough for podman - https://github.com/NixOS/nixpkgs/issues/138423
sudo apt-get install uidmap
```

If you encounter any errors in the above steps, Check and update CI and [wiki](https://github.com/kachick/dotfiles/wiki).
