# MicroVM Sandbox

```bash
nix run .#microvm-sandbox

# Inside the guest
sudo poweroff
```

- `/home/user/repos/github.com/kachick` is shared read-write with the host.
- `/nix/store` uses a volatile `tmpfs` overlay (`2G`) and resets on shutdown.

## Why not nixos-shell?

Evaluated [nixos-shell](https://github.com/Mic92/nixos-shell) as of 2026-11. Revisit if these points change:

- Broken on `nixos-unstable`: `2.2.0` in nixpkgs references removed `boot.initrd.systemd.enable`, and `main` fails to replace `--cache=always` in `run-nixos-vm` after the `run-virtiofsd-qemu` change.
- Depends directly on `qemu-vm.nix` runner script text, so upstream `nixpkgs` updates break it easily.
- Defaults to root autologin, full `$HOME` mount, and `.qcow2` disk files in the working directory instead of a volatile, scoped sandbox.
- Existing host configs (such as `moss`) hit host-specific checks like `zswap` without extra overrides.
