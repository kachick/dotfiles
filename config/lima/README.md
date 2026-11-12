# Lima

Linked to `~/.lima/` via [home-manager/lima-host.nix](../../home-manager/lima-host.nix).

## Base Environment

```bash
# Create clean base image (mounts ~/repos/github.com/kachick without $HOME)
limactl start --name=docker-nix-clean template:docker-nix
limactl stop docker-nix-clean
rm -rf ~/.lima/docker-nix-clean/sock # Avoid permission warnings in clones

# Clone daily instance (autostarts with user session)
limactl clone docker-nix-clean docker-nix --start
limactl shell docker-nix docker run --rm hello-world
```

## Disposable Sandbox

```bash
INSTANCE="sandbox-$(head -c 16 /dev/urandom | sha256sum | cut -c1-4)"

# Mount ~/repos/github.com/kachick like base
limactl clone docker-nix-clean "$INSTANCE" --start

# Or mount only current directory (do not mix --mount with --mount-only)
limactl clone docker-nix-clean "$INSTANCE" --mount-only .:w --start

lima --instance "$INSTANCE"
limactl delete -f "$INSTANCE"
```

## Windows Guest

See [windows-11.yaml](https://github.com/lima-vm/lima/blob/master/templates/windows-11.yaml).\
For `windows-11` instead of `windows-2025`, manually download the English ISO from [Microsoft](https://www.microsoft.com/en-us/software-download/windows11).
