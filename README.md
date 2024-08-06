# dotfiles

[![Home Status](https://github.com/kachick/dotfiles/actions/workflows/ci-home.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-home.yml?query=branch%3Amain+)
[![Home Status](https://github.com/kachick/dotfiles/actions/workflows/windows.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/windows.yml?query=branch%3Amain+)
[![Nix Status](https://github.com/kachick/dotfiles/actions/workflows/ci-nix.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-nix.yml?query=branch%3Amain+)
[![CI - Go Status](https://github.com/kachick/dotfiles/actions/workflows/ci-go.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-go.yml?query=branch%3Amain+)
[![Container Status](https://github.com/kachick/dotfiles/actions/workflows/container.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/container.yml?query=branch%3Amain+)

Personal dotfiles that can be placed in the public repository\
Also known as [盆栽(bonsai)](https://en.wikipedia.org/wiki/Bonsai) 🌳

## For visitors

If you are using [Podman](https://podman.io/), you can test the pre-built [ubuntu container-image](containers) as follows.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/kachick/dotfiles/main/containers/sandbox-with-ghcr.bash) latest
```

Or, you can directly use some commands with `nix run` without any installation steps.

```bash
nix run 'github:kachick/dotfiles#todo'
```

List them

```bash
nix flake show 'github:kachick/dotfiles' --json | jq '.apps | ."x86_64-linux" | keys[]'
```

## NixOS

Using flake style is disabled in NixOS by default and [you should inject git command to use flakes](https://www.reddit.com/r/NixOS/comments/18jyd0r/cleanest_way_to_run_git_commands_on_fresh_nixos/).

For example

```bash
nix --extra-experimental-features 'nix-command flakes' shell 'github:NixOS/nixpkgs/nixos-24.05#git' \
  --command sudo nixos-rebuild switch \
  --flake 'github:kachick/dotfiles#moss' \
  --show-trace
sudo reboot now
```

List defined hostnames

```bash
nix flake show 'github:kachick/dotfiles' --json | jq '.nixosConfigurations | keys[]'
```

## Ubuntu

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
   nix run 'github:kachick/dotfiles#home-manager' -- switch -b backup --flake 'github:kachick/dotfiles#user@linux-cui'
   ```

   Candidates
   - `user@linux-cui` # Used in container
   - `kachick@linux-gui`

### Podman on Ubuntu

1. Install uidmap without Nix for use of podman even if the podman will be installed from nixpkgs

   - "shadow" in nixpkg is not enough for podman - <https://github.com/NixOS/nixpkgs/issues/138423>

   ```bash
   sudo apt-get install --assume-yes uidmap
   ```

1. Make sure putting /etc/containers/policy.json, it is not a home-manager role

   ```bash
   sudo mkdir -p /etc/containers
   cd /etc/containers
   sudo curl -OL https://raw.githubusercontent.com/kachick/dotfiles/main/config/containers/policy.json
   ```

1. Make sure the cgroup v1 is disabled if you on WSL, See [the docs](windows/WSL/README.md)

1. Make sure you can run containers as `podman run public.ecr.aws/debian/debian:12.6-slim cat /etc/os-release`

## Debian

After installing missing tools, you can complete same steps as Ubuntu

```bash
sudo apt update
sudo apt upgrade
sudo apt install --assume-yes curl
sudo apt install --assume-yes dbus-user-session # For podman
```

Remember to set special config and reboot if you on WSL

```bash
echo '
[boot]
systemd=true' | sudo tee /etc/wsl.conf
```

## macOS

Activate `kachick@macbook` as Linux and [manually setup some packages](./darwin/README.md).

## Windows

After installing [WSL2](windows/WSL/README.md), you can activate home-manager and [NixOS-WSL](https://github.com/nix-community/NixOS-WSL).\
Read [Windows README](windows/README.md) and [CI](.github/workflows/windows.yml) for further detail.

## Multi-booting on Windows and Linux

Check [traps](./windows/Multi-booting.md)

## Following steps

1. Restore GPG secret from STDIN

   ```bash
   gpg --import
   ```

1. Restore SSH secret from STDIN

   ```bash
   touch ~/.ssh/id_ed25519 && chmod 400 ~/.ssh/id_ed25519
   micro ~/.ssh/id_ed25519
   ```

1. [Restore encrypted rclone.conf from STDIN](config/rclone.md)

1. Restore shell history

   [Work in Progress](https://github.com/kachick/dotfiles/pull/266)

## Note

If you are developing this repository, the simple reactivation is as follows.

```bash
makers apply user@linux-cui
```

If you encounter any errors in the above steps, Check and update CI and [wiki](https://github.com/kachick/dotfiles/wiki).
