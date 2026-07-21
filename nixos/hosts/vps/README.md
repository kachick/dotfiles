# NixOS Configuration for VPS (ConoHa VPS 3.0)

This directory contains the NixOS configuration for a VPS (QEMU/KVM guest) hosted on ConoHa VPS 3.0.

## Features & Requirements

1. **Target Environment**: ConoHa VPS 3.0 (KVM guest).
2. **Disk Layout**: Uses `disko` with BIOS/EFI hybrid support on `/dev/vda`.
3. **Dynamic Network Provisioning**: Automatically detects and configures IP address, subnet mask, and default gateway at boot using ConoHa VPS 3.0's OpenStack ConfigDrive (`/dev/disk/by-label/config-2`). No hardcoded IP addresses or private secret files are needed in this repository!
4. **Shell & Home Manager**: Default system shell is `bash` for lightweight console debugging. User-specific CLI tools, shell configs, and editor setups are managed declaratively via `home-manager`.

## Deploy Instructions

### Deploy via `nixos-anywhere`

Deploy NixOS to a fresh VPS 3.0 instance (Ubuntu etc.):

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#vps \
  --target-host root@<YOUR_VPS_IP> \
  --kexec-extra-flags "-c" \
  --debug
```

> **Note**: `--kexec-extra-flags "-c"` forces legacy `kexec_load` syscall to prevent `kexec_file_load` errors on certain Linux kernels.

### Update Existing System

To update the system after initial installation:

```bash
nixos-rebuild switch --flake .#vps --target-host root@<YOUR_VPS_IP>
```
