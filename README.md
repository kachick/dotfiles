# dotfiles

[![Nix](https://github.com/kachick/dotfiles/actions/workflows/nix.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/nix.yml?query=branch%3Amain+)
[![Windows](https://github.com/kachick/dotfiles/actions/workflows/windows.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/windows.yml?query=branch%3Amain+)

Personal dotfiles that can be placed in the public repository\
Also known as [盆栽(bonsai)](https://en.wikipedia.org/wiki/Bonsai) 🌳

## Daily Operations

Apply config:

```bash
# For non-NixOS:
echo 'HM_HOST_SLUG=wsl-ubuntu' >.env

task apply
```

Start a sandbox:

```bash
nix run .#microvm-sandbox

# Pre-built container
task ghcr
```

## Bootstrapping

```bash
walk ' README'
```
