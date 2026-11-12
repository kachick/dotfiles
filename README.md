# dotfiles

[![Nix on Linux](https://github.com/kachick/dotfiles/actions/workflows/nix.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/nix.yml?query=branch%3Amain+)
[![Windows](https://github.com/kachick/dotfiles/actions/workflows/windows.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/windows.yml?query=branch%3Amain+)
[![Container](https://github.com/kachick/dotfiles/actions/workflows/container.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/container.yml?query=branch%3Amain+)

Personal dotfiles that can be placed in the public repository\
Also known as [盆栽(bonsai)](https://en.wikipedia.org/wiki/Bonsai) 🌳

## Daily Operations

Apply NixOS or Home Manager configuration:

```bash
task apply
```

For non-NixOS Home Manager environments, set `HM_HOST_SLUG` in `.env` first:

```bash
echo 'HM_HOST_SLUG=wsl-ubuntu' >.env
```

Run tests and linters:

```bash
task check
```

Start an isolated sandbox:

```bash
# NixOS MicroVM
nix run .#microvm-sandbox

# Pre-built Podman container
bash <(curl -fsSL https://raw.githubusercontent.com/kachick/dotfiles/main/containers/sandbox.bash) --ghcr latest
```

Run or list exposed flake packages:

```bash
nix run 'github:kachick/dotfiles#todo'
nix flake show 'github:kachick/dotfiles' --json 2>/dev/null | jq '.packages | ."x86_64-linux" | to_entries | map("\(.key) # \(.value.description)")'
```

## Guides and Directory Layout

- [nixos/](nixos/README.md): NixOS system configurations, fresh bootstrap, and module inheritance
- [nixos/hosts/sandbox/](nixos/hosts/sandbox/README.md): Disposable MicroVM sandbox (`microvm-sandbox`)
- [home-manager/](home-manager/README.md): Home Manager configurations, Ubuntu/Debian bootstrap, and FAQ
- [pkgs/](pkgs/README.md) / [overlays/](overlays/README.md): Local (`pkgs.local`) and pinned (`pkgs.pinned`) packages and overlays
- [containers/](containers/README.md): Podman systemd container and Nix layered image
- [config/lima/](config/lima/README.md): Lima VM (`docker-nix`) setup and Windows guest notes
- [windows/](windows/README.md) / [windows/WSL/](windows/WSL/README.md) / [Multi-booting](windows/Multi-booting.md): Windows setup, WSL2 (NixOS-WSL and Ubuntu), and dual-boot notes
- [Wiki: Encryption](https://github.com/kachick/dotfiles/wiki/Encryption): GPG and Passage secret setup
