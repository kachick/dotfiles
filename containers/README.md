# Containers

Base image (`ghcr.io/kachick/ubuntu-26.04-nix-systemd`) is maintained in [kachick/containers](https://github.com/kachick/containers).
[layered-image.nix](./layered-image.nix) layers the Nix store closure and Home Manager configuration (`user@container`) on top of that Ubuntu + systemd base image using `dockerTools.buildLayeredImage`.

## Build and test locally

```bash
# Build and stream-load into podman
task build-container

# Or build the compressed tarball and load with progress
nix build .#container-layered
pv result | podman load

# Run smoke tests
task test-container

# Start an interactive login shell
task sandbox
```
