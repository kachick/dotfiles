# WSL

Uses WSL 3.0+ package (still runs the WSL 2 architecture; `.wslconfig` keeps `[wsl2]`).

```pwsh
# Update to WSL 3.0+ (includes wslc.exe; prefer wsl.exe over winget Microsoft.WSL to keep Windows features in sync)
wsl.exe --update
wsl.exe --version
```

## NixOS on WSL

Uses [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) (no `/etc/nixos/hardware-configuration.nix`; [default username is `nixos`](https://github.com/nix-community/NixOS-WSL/blob/269411cfed6aab694e46f719277c972de96177bb/docs/src/how-to/change-username.md)):

```pwsh
wsl.exe --install --no-distribution
curl -OL "https://github.com/nix-community/NixOS-WSL/archive/refs/heads/release-26.05.tar.gz"
wsl.exe --import NixOS $env:USERPROFILE\NixOS\ nixos-wsl.tar.gz
wsl.exe --distribution "NixOS"
```

```bash
sudo nix-channel --update
```

## Ubuntu on WSL

```pwsh
wsl.exe --install "Ubuntu-26.04"
wsl.exe --distribution "Ubuntu-26.04"
```

Set up Nix and Home Manager (`visitor@wsl-ubuntu`) following [home-manager/README.md](../../home-manager/README.md).

Disable cgroup v1 with [.wslconfig](.wslconfig) for rootless Podman:

```pwsh
winit-conf.exe generate -path=windows/WSL/.wslconfig > %UserProfile%\.wslconfig
wsl.exe --shutdown
```

## Tips

```bash
# Open current WSL directory in Windows Explorer
explorer.exe .

# Jump to a Windows path from WSL
z "$(wslpath 'G:\GoogleDrive')"
```

```pwsh
# Recover when login shell is broken in WSL
wsl --user root
```
