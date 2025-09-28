# Windows Subsystem for Linux (WSL) Guide

This guide covers the setup and usage of WSL (Windows Subsystem for Linux), including NixOS and Ubuntu distributions.

## General WSL Tips

### How do I install WSL2?

`winget` does not currently support the initial installation of WSL2. Follow the official Microsoft documentation to install it.

### How do I open the current directory in Windows Explorer from a WSL shell?

Run the following command inside your WSL shell:

```bash
explorer.exe .
```

### How do I navigate to a Windows folder from a WSL shell?

Use the `wslpath` utility to convert the Windows path. This can be combined with tools like `z` for quick navigation.

```bash
z "$(wslpath 'G:\\GoogleDrive')"
```

### How do I fix a broken login shell in WSL2?

If your default login shell is broken, you can log in as the `root` user to fix it.

```powershell
wsl --user root
```

---

## NixOS on WSL2

This setup uses the community-maintained [NixOS-WSL](https://github.com/nix-community/NixOS-WSL).

**Important Notes:**

- This environment does not have an `/etc/nixos/hardware-configuration.nix` file.
- The [default username is `nixos`](https://github.com/nix-community/NixOS-WSL/blob/main/docs/src/how-to/change-username.md).

### Installation

1. Run the following commands in PowerShell to download and import the NixOS distribution:

   ```powershell
   wsl.exe --install --no-distribution
   curl -OL "https://github.com/nix-community/NixOS-WSL/releases/download/2405.5.4/nixos-wsl.tar.gz"
   wsl.exe --import NixOS "$env:USERPROFILE\NixOS" nixos-wsl.tar.gz
   wsl.exe --distribution "NixOS"
   ```

2. Inside the NixOS shell, update the Nix channels:

   ```bash
   ```

sudo nix-channel --update

````
3. Follow the main [README](../README.md) to set up Nix and activate the Home Manager configuration using the `kachick@wsl-nixos` profile.

---

## Ubuntu on WSL2

### Installation

1. Install and launch the Ubuntu distribution from PowerShell:

   ```powershell
   wsl.exe --install "Ubuntu-24.04"
   wsl.exe --distribution "Ubuntu-24.04"
````

2. Follow the main [README](../README.md) to set up Nix and activate the Home Manager configuration using the `kachick@wsl-ubuntu` profile.

### Podman Configuration

To use Podman, you need to disable cgroup v1.

1. Generate the `.wslconfig` file in your Windows user profile directory:

   ```powershell
   ```

winit-conf.exe generate -path=windows/WSL/.wslconfig > "$env:USERPROFILE\.wslconfig"

````
2. Shut down WSL to apply the changes. It will restart automatically when you next open a WSL shell.

   ```powershell
````

wsl.exe --shutdown

```
```
