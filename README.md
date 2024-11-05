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
  --flake "github:kachick/dotfiles#$(hostname)" \
  --show-trace
sudo reboot now
```

List defined hostnames

```bash
nix flake show 'github:kachick/dotfiles' --json | jq '.nixosConfigurations | keys[]'
```

This repository intentionally reverts the home-manager NixOS module.\
So, you should activate the user dotfiles with standalone home-manager even though NixOS.

```bash
nix run 'github:kachick/dotfiles#home-manager' -- switch -b backup --flake 'github:kachick/dotfiles#kachick@desktop'
```

See [GH-680](https://github.com/kachick/dotfiles/issues/680) for background

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
   nix run 'github:kachick/dotfiles#home-manager' -- switch -b backup --flake 'github:kachick/dotfiles#user@linux-cli'
   ```

   Candidates
   - `user@linux-cli` # Used in container

1. If you faced to lcoale errors such as `-bash: warning: setlocale: LC_TIME: cannot change locale (en_DK.UTF-8): No such file or directory`

   ```bash
   sudo localedef -f UTF-8 -i en_DK en_DK.UTF-8
   ```

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

## Windows

After installing [WSL2](windows/WSL/README.md), you can activate home-manager and [NixOS-WSL](https://github.com/nix-community/NixOS-WSL).\
Read [Windows README](windows/README.md) and [CI](.github/workflows/windows.yml) for further detail.

## Multi-booting on Windows and Linux

Check [traps](./windows/Multi-booting.md)

## macOS

I basically [give up to maintain macOS environment](https://github.com/kachick/dotfiles/issues/911). Use [lima](https://github.com/lima-vm/lima) for development tasks as use of WSL2 in Windows

1. Add minimum packages with home-manager. Apply home-manager with `kachick@macbook`
2. Manually setup [lima](https://github.com/kachick/dotfiles/issues/146#issuecomment-2453430154)(default Ubuntu guest) and [some packages](https://github.com/kachick/dotfiles/wiki/macOS) without Nix
3. In the lima as `limactl start`, apply home-manager with `kachick@lima`
4. You can run containers as `lima nerdctl run --rm hello-world` or podman after avobe `Podman on Ubuntu` setups

## How to setup secrets

Extracted to [wiki](https://github.com/kachick/dotfiles/wiki/Encryption)

## Note

If you are developing this repository, the simple reactivation is as follows.

```bash
makers apply 'kachick@wsl'
```

For NixOS

```bash
sudo nixos-rebuild switch --flake ".#$(hostname)" --show-trace && \
    makers apply 'kachick@desktop'
```

If you encounter any errors in the above steps, Check and update CI and [wiki](https://github.com/kachick/dotfiles/wiki).
