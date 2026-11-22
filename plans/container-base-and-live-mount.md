# Base Image Slimming (`kachick/containers`) and Live-Mount Staging Mode

## Goal

1. Slim down the base image in `kachick/containers` (or add a dedicated `ubuntu-systemd` base image) so it does not install a duplicate Nix closure via `nix-installer` that `kachick/dotfiles` immediately overrides.
2. Provide an optional `--live` mode in `containers/sandbox.bash` for instant zero-build container testing when needed.

## Background: What `kachick/dotfiles` Currently Overrides

In [containers/layered-image.nix](../containers/layered-image.nix), `dockerTools.buildLayeredImage` layers `homeConfigurations."user@container".activationPackage` and `pkgs.nix` on top of `fromImage` (`ghcr.io/kachick/ubuntu-26.04-nix-systemd`):

- `includeNixDB = true` generates a fresh `/nix/var/nix/db/db.sqlite` containing `pkgs.nix` and the Home Manager closure, replacing the SQLite DB from `fromImage`.
- `/etc/nix/nix.conf`, `/nix/var/nix/profiles/default`, `/etc/systemd/system/nix-daemon.service`, `/etc/systemd/system/nix-daemon.socket`, and `/etc/systemd/system/sockets.target.wants/nix-daemon.socket` are all symlinked to `pkgs.nix` from `dotfiles`.

As a result, the `nix-installer` step in `kachick/containers` leaves ~150-200 MB of unreferenced Nix store paths in the base layers, while only its `/etc/passwd` (`nixbld*` users) is actually used.

## Part 1: Slim Base Image in `kachick/containers`

### Option A: Add `images/ubuntu-systemd/Containerfile` (Recommended if `ubuntu-nix-systemd` is still used standalone)

Create a new image in `kachick/containers` (`ghcr.io/kachick/ubuntu-26.04-systemd`) that prepares Ubuntu 26.04, `systemd`, `user`, and the `nixbld` group/users without downloading or running `nix-installer`:

```dockerfile
FROM public.ecr.aws/docker/library/buildpack-deps:26.04-scm@sha256:94fb43e4b298af21cdecc40f1f1bb41d9ac13606eaedce7009c889ff43912aa9

LABEL org.opencontainers.image.source=https://github.com/kachick/containers
LABEL org.opencontainers.image.description="Ubuntu 26.04 with systemd pre-configured for layered Nix images"
LABEL org.opencontainers.image.licenses=MIT

RUN apt-get update \
 && apt-get install --no-install-recommends -y systemd \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Create nixbld group and build users (30001..30032) for multi-user nix-daemon
RUN groupadd --gid 30000 --system nixbld \
 && for i in $(seq 1 32); do \
      useradd \
        --home-dir /var/empty \
        --gid 30000 \
        --groups nixbld \
        --no-user-group \
        --system \
        --shell /usr/sbin/nologin \
        --uid "$((30000 + i))" \
        "nixbld${i}"; \
    done

ARG username="user"
RUN useradd --no-log-init --create-home --uid 1000 "$username"

CMD ["/usr/lib/systemd/systemd", "--system"]
```

### Option B: Replace `nix-installer` in `images/ubuntu-nix-systemd/Containerfile`

If `kachick/containers` is only used as the base image for `kachick/dotfiles`, apply the Dockerfile changes above directly to `images/ubuntu-nix-systemd/Containerfile`.

### Updating `containers/layered-image.nix` in `kachick/dotfiles`

Once the new or updated base image is published to GHCR:

1. Fetch the new image digest:

   ```bash
   skopeo inspect docker://ghcr.io/kachick/ubuntu-26.04-systemd:latest | jq -r '.Digest'
   ```

2. Update `imageName` and `imageDigest` in [containers/layered-image.nix](../containers/layered-image.nix), set `hash = "";`, run `nix build .#container-layered.passthru.stream`, and paste the computed `sha256-...` hash.
3. Because [containers/layered-image.nix](../containers/layered-image.nix) dynamically extracts `user`'s `UID:GID` from `baseImage`'s `/etc/passwd` and creates `/etc/systemd/system/sockets.target.wants/nix-daemon.socket` and `/nix/var/nix/daemon-socket`, no other changes are required.

## Part 2: Optional `--live` Mode in `containers/sandbox.bash`

For testing `apply-system` or `home-manager switch` activation scripts directly inside a running container without building an image first:

1. Add a `--live` option to [containers/sandbox.bash](../containers/sandbox.bash).
2. When `--live` is passed, start `localhost/home:latest` (or `ghcr.io/kachick/ubuntu-26.04-nix-systemd:latest`) with `--volume "${PWD}:/workspace/dotfiles:ro"` and enter the shell so changes in the working tree can be applied immediately with `nix run /workspace/dotfiles#home-manager -- switch --flake /workspace/dotfiles#user@container`.

## Verification Checklist

1. `task build-container`
2. `task test-container`
3. `task fmt`
4. `task lint-all`
