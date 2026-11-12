# MicroVM Sandbox

This directory defines a disposable NixOS MicroVM (`nixosConfigurations.sandbox`) for isolated testing and agent development.

## Usage

Start the sandbox from the repository root:

```bash
nix run .#microvm-sandbox
```

The VM boots into a serial console and logs in automatically as `user` (`wheel` group with passwordless `sudo`).

To exit and shut down the VM:

```bash
sudo poweroff
```

## Architecture

- **Hypervisor and Network**: Runs on rootless QEMU (`microvm.nix`) with user-mode networking (`SLiRP`). No root privileges or host bridge setup are required.
- **Ephemeral Nix Store**: Mounts the host `/nix/store` read-only over 9p and layers a 2 GB `tmpfs` writable overlay (`/nix/.rw-store`). Packages built or installed inside the VM do not modify the host store and are discarded on shutdown.
- **Shared Repositories**: Mounts host `/home/kachick/repos/github.com/kachick` read-write at `/home/user/repos/github.com/kachick` over 9p.
- **Dynamic UID Synchronization**: At boot, `sync-user-uid.service` updates the guest `user` UID to match the owner of the mounted `repos` directory before `home-manager-user.service` runs.
