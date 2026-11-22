# Fast Host-Store Container Sandbox Mode and Base Image Trimming

## Goal

Provide an instant, zero-build container staging mode in `containers/sandbox.bash` for testing non-NixOS (`apply-system` and `home-manager switch`) changes without waiting for full image layer generation, and document optional trimming of `kachick/containers`.

## Background

[containers/layered-image.nix](../containers/layered-image.nix) now builds a 100-layer image on top of `ghcr.io/kachick/ubuntu-26.04-nix-systemd` (`fromImage`), eliminating `podman commit` and enabling fine-grained layer caching across `nixpkgs` updates.

Two optional follow-up improvements remain:

1. **Live host-store mount mode (`containers/sandbox.bash --live`)**:
   - When iterating on `apply-system` or `home-manager` activation scripts locally on a Linux host with `/nix/store`, mounting the host store and current repository into `ghcr.io/kachick/ubuntu-26.04-nix-systemd` lets an agent or developer test activation scripts in 1 second without building an image first.
2. **Simplifying `kachick/containers` (`ubuntu-nix-systemd`)**:
   - Because `containers/layered-image.nix` supplies `pkgs.nix`, `/etc/nix/nix.conf`, `nix-daemon.service`, and the Nix SQLite database (`includeNixDB = true`), the base image in `kachick/containers` only strictly needs Ubuntu 26.04, `systemd`, and the `user` account.

## Design Specification

### Part 1: Optional `--live` Mode in `containers/sandbox.bash`

Add a `--live` flag to [containers/sandbox.bash](../containers/sandbox.bash) that starts the base image (`ghcr.io/kachick/ubuntu-26.04-nix-systemd:latest`) with the current repository mounted at `/workspace/dotfiles`:

1. Parse `--live` in `containers/sandbox.bash`.
2. Start `ghcr.io/kachick/ubuntu-26.04-nix-systemd:latest` detached with:
   - `--volume "${PWD}:/workspace/dotfiles:ro"`
3. Wait 1 second for systemd to start, then run or allow the user/agent to test:
   - `podman exec --user=root "$container_id" nix run '/workspace/dotfiles#apply-system'`
   - `podman exec --user=user "$container_id" nix run '/workspace/dotfiles#home-manager' -- switch -b backup --flake '/workspace/dotfiles#user@container'`

### Part 2: Base Image Update Helper

When `ghcr.io/kachick/ubuntu-26.04-nix-systemd` is updated in `kachick/containers`, `baseImage` in [containers/layered-image.nix](../containers/layered-image.nix) needs both `imageDigest` and `hash`.

Add a helper task or comment in [containers/layered-image.nix](../containers/layered-image.nix) showing the exact two commands to refresh the digest and Nix hash:

```bash
# 1. Fetch latest digest from GHCR
skopeo inspect docker://ghcr.io/kachick/ubuntu-26.04-nix-systemd:latest | jq -r '.Digest'

# 2. Prefetch Nix fixed-output hash
nix store prefetch-file --json ... # or nix build .#container-layered
```

## Verification Checklist

1. `task fmt`
2. `task lint-all`
3. `task test-container`
