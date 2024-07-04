# Windows Subsystem for Linux

## How to install WSL2?

winget does not support it, run as follows

## How to open current directory in WSL2 with Windows Explorer?

In WSL shell

```bash
explorer.exe .
```

## How to move on Windows folder from WSL2?

```bash
z "$(wslpath 'G:\GoogleDrive')"
```

## Login shell has been broken in WSL2

```pwsh
wsl --user root
```

## Setup NixOS on WSL2

Use [NixOS](https://github.com/nix-community/NixOS-WSL).\
You should remember that does not have `/etc/nixos/hardware-configuration.nix` and the [default username is `nixos`](https://github.com/nix-community/NixOS-WSL/blob/269411cfed6aab694e46f719277c972de96177bb/docs/src/how-to/change-username.md).

```pwsh
wsl.exe --install --no-distribution
curl -OL "https://github.com/nix-community/NixOS-WSL/releases/download/2311.5.3/nixos-wsl.tar.gz"
wsl.exe --import NixOS $env:USERPROFILE\NixOS\ nixos-wsl.tar.gz
wsl.exe --distribution "NixOS"
```

```bash
sudo nix-channel --update
sudo nixos-generate-config
# Remove the entry for /mnt/wslg/distro if that has empty `device = "";`. See https://github.com/Misterio77/nix-starter-configs/issues/49

nix --extra-experimental-features 'nix-command flakes' shell 'github:NixOS/nixpkgs/nixos-24.05#git' \
  --command sudo nixos-rebuild switch \
  --impure --flake 'github:kachick/dotfiles#nixos-wsl'
sudo reboot now
```

## Setup Ubuntu on WSL2

```pwsh
wsl.exe --install "Ubuntu-24.04"
wsl.exe --distribution "Ubuntu-24.04"
```

Setup nix and activate home-manager as written in [README](../README.md) with `kachick@wsl`
