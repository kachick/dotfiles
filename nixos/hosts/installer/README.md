# Recovery Live ISO (`installer`)

Volatile NixOS desktop Live ISO for recovery and installation. Built in CI without unfree AI model weights so the ISO stays safe to distribute publicly while still supporting offline translation and shared storage from a MultiOS-USB drive.

## MultiOS-USB Setup

```bash
# List removable USB devices
sudo multios-usb --devices

# Initialize a USB drive with a 16G MultiOS-USB partition for ISOs (erases existing data)
sudo multios-usb /dev/sdX 16G

# Create a 3rd partition (SHARED_DATA) from the remaining space for everyday + Live rw use
sudo sgdisk -n 3:0:0 -t 3:0700 -c 3:"Shared Data" /dev/sdX
sudo partprobe /dev/sdX
sudo mkfs.exfat -n SHARED_DATA /dev/sdX3

# Build the ISO locally, copy to MultiOS-USB, and remove the ISO store path right away
task copy-installer-iso

# Or copy an optional local PLaMo GGUF onto SHARED_DATA
find ~/.cache -name '*plamo-3-translate-0.8b*.gguf' \
	-exec cp --dereference {} "/run/media/${USER}/SHARED_DATA/" \;
sync

# Fallback: copy a CI-built ISO downloaded from GitHub Actions instead of building locally
cp ~/Downloads/nixos-*.iso "/run/media/${USER}/MultiOS-USB/ISOs/"
sync
```

### Optional Rescue ISOs (exFAT-Compatible)

MultiOS-USB formats its ISO partition as exFAT by default. Ubuntu/Xubuntu and upstream NixOS minimal ISOs do not boot from exFAT in MultiOS-USB, so use exFAT-compatible images for backup rescue entries:

- [SystemRescue](https://www.system-rescue.org/Download/) (`systemrescue-*-amd64.iso`, ~1.3 GiB): lightweight disk and boot repair tools.
- [Fedora Xfce Spin](https://fedoraproject.org/spins/xfce/download) (`Fedora-Xfce-Live-*.x86_64.iso`, ~2.8 GiB): Secure Boot-ready desktop fallback with a recent kernel (keep the upstream filename so MultiOS-USB matches `fedora-live.cfg`).

```bash
# Download the latest ISOs and checksum files into a temporary directory, verify, then copy to USB
sha256sum --check systemrescue-*-amd64.iso.sha256
sha256sum --ignore-missing --check Fedora-Spins-*-x86_64-CHECKSUM
cp --verbose systemrescue-*-amd64.iso Fedora-Xfce-Live-*.x86_64.iso "/run/media/${USER}/MultiOS-USB/ISOs/"
sync
```

## Boot and Storage Flow

```mermaid
flowchart TD
    subgraph USB ["USB Stick (GPT)"]
        efi_part["p1: MultiOS-EFI (FAT16, bootloader)"]
        iso_part["p2: MultiOS-USB (exFAT, /ISOs/nixos-*.iso)"]
        shared_part["p3: SHARED_DATA (exFAT, everyday + Live rw)"]
    end

    direct["Direct-burn USB or VM"] -->|"no findiso="| stage1_iso

    iso_part -->|"GRUB loopback.cfg sets findiso="| finder

    subgraph Initrd ["Stage 1 (systemd initrd)"]
        finder["loopback-iso-finder.service (ConditionKernelCommandLine=findiso)"]
        host_mnt["/run/loopback-host (ro)"]
        loop_dev["losetup --read-only --partscan"]
        stage1_iso["sysroot-iso.mount (/dev/disk/by-label/nixos-*)"]
        overlay["/nix/.ro-store (squashfs) + /nix/.rw-store (tmpfs) -> /nix/store"]
    end

    finder -->|"mount p2 ro"| host_mnt
    host_mnt --> loop_dev
    loop_dev --> stage1_iso
    stage1_iso --> overlay

    subgraph Session ["Live User Session (nixos, auto-login, tmpfs home)"]
        shared_mnt["/mnt/shared (rw, x-systemd.automount)"]
        autostart["llama-plamo-offline-autostart.service (ConditionPathExistsGlob)"]
        plamo_svc["llama-plamo.service (start-llama-plamo)"]
        offline_srv["llama-server --model (offline)"]
        online_srv["llama-server -hf (download into tmpfs)"]
        manual["Manual: plamo start"]
    end

    overlay --> shared_mnt
    shared_part -->|"LABEL=SHARED_DATA"| shared_mnt
    shared_mnt -.->|"check local GGUF"| autostart
    host_mnt -.->|"fallback GGUF lookup"| autostart
    autostart -->|"GGUF exists -> systemctl start"| plamo_svc
    manual --> plamo_svc
    plamo_svc -->|"GGUF found"| offline_srv
    plamo_svc -->|"no local GGUF"| online_srv
```

- All writes under `/` and `/home/nixos` live in RAM (`tmpfs`) and vanish on shutdown.
- `MultiOS-USB` stays read-only at `/run/loopback-host` during Live boots to protect the mounted ISO, while `SHARED_DATA` mounts read-write at `/mnt/shared` for general files and local GGUF models.
- `loopback-iso-finder.service` is skipped on direct-burn USBs and VMs because `findiso` is absent from `/proc/cmdline`.
- Without a local GGUF on `/mnt/shared` or `/run/loopback-host`, `llama-plamo` does not auto-start to avoid filling `tmpfs`, while manual `plamo start` falls back to `-hf`.

## Local VM Verification

Test MultiOS-USB loopback boot locally in QEMU + OVMF instead of writing a physical USB stick (kept out of CI to avoid heavy VM runs):

- Build a 6 GiB GPT raw image with `p1` (`MultiOS-EFI`, FAT16 via `mkfs.vfat` + `mcopy`) and `p2` (`MultiOS-USB`, exFAT via `mkfs.exfat`).
- Because the ISO is larger than the 4 GiB FAT32 limit and exFAT has no rootless copy tool like `mcopy`, fill `p2` by booting the ISO once in QEMU (`plymouth.enable=0 console=ttyS0,115200n8`) with `virtio-9p` mounts and copying `MultiOS-USB/` and `ISOs/*.iso` onto `p2`.
- Boot the virtual USB read-only over UEFI (`-drive if=pflash,format=raw,readonly=on,file=/run/current-system/sw/share/qemu/edk2-x86_64-code.fd`) and attach it via `-device qemu-xhci -device usb-storage,drive=usb0` so stage 1 sees `/dev/sda*` like real hardware.
- Drive GRUB menus over the QEMU monitor (`sendkey` / `screendump`) and verify Live boot via forwarded SSH (`hostfwd=tcp:127.0.0.1:<port>-:22`).
- Inspect initrd modules without booting via `zstd -dc <initrd> | cpio -t`.
