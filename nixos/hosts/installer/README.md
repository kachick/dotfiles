# Recovery Live ISO (`installer`)

Volatile NixOS desktop Live ISO for recovery and installation. Built in CI without unfree AI model weights so the ISO stays safe to distribute publicly while still supporting offline translation from a MultiOS-USB data partition.

## MultiOS-USB Setup

```bash
# List removable USB devices
sudo multios-usb --devices

# Initialize a USB drive once (erases existing data on the drive)
sudo multios-usb /dev/sdX

# Copy the CI-built ISO and optional local PLaMo GGUF onto the mounted MultiOS-USB partition
USB_DIR="/run/media/${USER}/MultiOS-USB"
cp ~/Downloads/nixos-*.iso "${USB_DIR}/ISOs/"
mkdir --parents "${USB_DIR}/models"
find ~/.cache -name '*plamo-3-translate-0.8b*.gguf' -exec cp --dereference {} "${USB_DIR}/models/" \;
sync

# Build the ISO locally instead of downloading from CI
nix build ".#nixosConfigurations.installer.config.system.build.isoImage" --show-trace
```

## Boot and Offline Translation Flow

```mermaid
flowchart TD
    subgraph USB ["MultiOS-USB Partition (exFAT / ext4)"]
        iso_file["/ISOs/nixos-*.iso"]
        gguf_file["/models/*plamo-3-translate-0.8b*.gguf (optional)"]
    end

    direct["Direct-burn USB or VM"] -->|"no findiso="| stage1_iso

    iso_file -->|"GRUB loopback.cfg sets findiso="| finder

    subgraph Initrd ["Stage 1 (systemd initrd)"]
        finder["loopback-iso-finder.service (ConditionKernelCommandLine=findiso)"]
        host_mnt["/run/loopback-host (ro)"]
        loop_dev["losetup --read-only --partscan"]
        stage1_iso["sysroot-iso.mount (/dev/disk/by-label/nixos-*)"]
        overlay["/nix/.ro-store (squashfs) + /nix/.rw-store (tmpfs) -> /nix/store"]
    end

    finder -->|"mount USB partition"| host_mnt
    host_mnt --> loop_dev
    loop_dev --> stage1_iso
    stage1_iso --> overlay

    subgraph Session ["Live User Session (nixos, auto-login, tmpfs home)"]
        autostart["llama-plamo-offline-autostart.service (ConditionPathExistsGlob)"]
        plamo_svc["llama-plamo.service (start-llama-plamo)"]
        offline_srv["llama-server --model (offline)"]
        online_srv["llama-server -hf (download into tmpfs)"]
        manual["Manual: plamo start"]
    end

    overlay --> autostart
    gguf_file -.->|"visible via /run/loopback-host"| autostart
    autostart -->|"GGUF exists -> systemctl start"| plamo_svc
    manual --> plamo_svc
    plamo_svc -->|"GGUF found"| offline_srv
    plamo_svc -->|"no local GGUF"| online_srv
```

- All writes under `/` and `/home/nixos` live in RAM (`tmpfs`) and vanish on shutdown.
- `loopback-iso-finder.service` is skipped on direct-burn USBs and VMs because `findiso` is absent from `/proc/cmdline`.
- Without a local GGUF on `/run/loopback-host`, `llama-plamo` does not auto-start to avoid filling `tmpfs`, while manual `plamo start` falls back to `-hf`.
