# dotfiles

[![Home Status](https://github.com/kachick/dotfiles/actions/workflows/ci-home.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-home.yml?query=branch%3Amain+)
[![Home Status](https://github.com/kachick/dotfiles/actions/workflows/windows.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/windows.yml?query=branch%3Amain+)
[![Nix Status](https://github.com/kachick/dotfiles/actions/workflows/ci-nix.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-nix.yml?query=branch%3Amain+)
[![CI - Go Status](https://github.com/kachick/dotfiles/actions/workflows/ci-go.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-go.yml?query=branch%3Amain+)
[![Container Status](https://github.com/kachick/dotfiles/actions/workflows/container.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/container.yml?query=branch%3Amain+)

Personal dotfiles that can be placed in the public repository\
Also known as [盆栽(bonsai)](https://en.wikipedia.org/wiki/Bonsai) 🌳

```mermaid
block-beta
    columns 3

    block:os:3
        nixos(("❄")) macos(("🍎"))   windows(("🪟"))
    end

    block:vm:3
        lima("Lima")   wsl2("WSL2")
    end

    block:container:3
        podman("🦭") k8s("☸️") 
    end

    nixos --> lima
    macos --> lima
    windows --> wsl2

    vm --> container
    nixos --> container
```

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
nix flake show 'github:kachick/dotfiles' --json 2>/dev/null | jq '.packages | ."x86_64-linux" | to_entries | map("\(.key) # \(.value.description)")'
```

## NixOS

Using flake style is disabled in NixOS by default and [you should inject git command to use flakes](https://www.reddit.com/r/NixOS/comments/18jyd0r/cleanest_way_to_run_git_commands_on_fresh_nixos/).

For example

```bash
nix --extra-experimental-features 'nix-command flakes' shell 'github:NixOS/nixpkgs/nixos-24.11#git' \
  --command sudo nixos-rebuild switch \
  --flake "github:kachick/dotfiles#$(hostname)" \
  --show-trace
sudo reboot now
```

List defined hostnames

```bash
nix flake show 'github:kachick/dotfiles' --json 2>/dev/null | jq '.nixosConfigurations | keys[]'
```

This repository intentionally reverts the home-manager NixOS module.\
So, you should activate the user dotfiles with standalone home-manager even though NixOS.

```bash
nix run 'github:kachick/dotfiles#home-manager' -- switch -b backup --flake 'github:kachick/dotfiles#kachick@nixos-desktop'
```

See [GH-680](https://github.com/kachick/dotfiles/issues/680) for background

NixOS is often difficult for beginners like me. So I also use [Lima](#lima) for several issues.

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

1. [home-manager installed OpenSSH disabled GSSAPI by default](https://github.com/kachick/dotfiles/issues/950).\
   So suppress `/etc/ssh/ssh_config line 53: Unsupported option "gssapiauthentication"` with following command

   ```bash
   sudo chmod -r /etc/ssh/ssh_config
   ```

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

1. Install [WSL2](windows/WSL/README.md) with default Ubuntu. Activate home-manager as `kachick@wsl-ubuntu`
1. Install [NixOS-WSL](https://github.com/nix-community/NixOS-WSL). Activate home-manager with `$(whoami)@wsl-nixos`
1. Adjust Windows experience as written in [extracted steps](windows/README.md) and as written in [CI](.github/workflows/windows.yml) for further detail.

## Multi-booting on Windows and Linux

Check [traps](./windows/Multi-booting.md)

## macOS

I basically [give up to maintain macOS environment](https://github.com/kachick/dotfiles/issues/911).

1. Apply home-manager with `kachick@macbook` for minimum packages.
1. Install [some packages](https://github.com/kachick/dotfiles/wiki/macOS) without Nix
1. Use [Lima](#lima) for development tasks.

## Lima

1. Setup [Lima](https://github.com/lima-vm/lima) with default Ubuntu guest
1. In the lima as `limactl start`, apply home-manager with `kachick@lima`
1. You can run containers as `lima nerdctl run --rm hello-world`. You can also use podman after above `Podman on Ubuntu` setups

## How to setup secrets

Extracted to [wiki](https://github.com/kachick/dotfiles/wiki/Encryption)

## Shorthand

If you are developing this repository, putting `.env` makes easy reactivations.

```bash
echo 'HM_HOST_SLUG=wsl-ubuntu' > .env
```

Then you can enable configurations with

```bash
task apply
```
