# Containers

Base image (`ghcr.io/kachick/ubuntu-26.04-systemd`) is maintained in [kachick/containers](https://github.com/kachick/containers).
[layered-image.nix](./layered-image.nix) layers the Nix store closure and Home Manager configuration (`user@container`) on top of that Ubuntu + systemd base image using `dockerTools.buildLayeredImage`.

## Image Composition (`layered-image.nix`)

```mermaid
flowchart TD
    subgraph Inputs ["Flake Inputs & Configs"]
        base_json["base-image.json (ghcr.io/kachick/ubuntu-26.04-systemd)"]
        hm_cfg["homeConfigurations.user@container (activationPackage)"]
        nix_cfg["nixos/nix.nix + container overrides (sandbox = false, extra-trusted-users = user)"]
        sys_cfg["pkgs.nix / glibcLocales / corePackages / config/{containers,tailscaled}"]
    end

    subgraph Image ["dockerTools.buildLayeredImage (home:latest)"]
        base_layers["Base Layers: Ubuntu 26.04 FHS (/bin, /usr, /lib, /etc) & PID 1 systemd --system"]
        store_layers["Nix Store Layers (maxLayers = 100, includeNixDB = true): /nix/store & /nix/var/nix/db (extraCommands strips top-level /bin, /etc, /usr symlinks)"]

        subgraph FakeRoot ["Top Customization Layer (fakeRootCommands)"]
            passwd["/etc/passwd & /etc/group: extract_from_base + nixbld1..32, dynamic user UID/GID chown"]
            daemon["Nix Daemon: /etc/nix/nix.conf, nix-daemon.{service,socket}, /nix/var/nix/profiles/default"]
            sys_etc["System Config: /usr/lib/locale/locale-archive, /etc/containers/policy.json, tailscaled.service"]
            hm_state["Home Manager (/home/user): .nix-profile -> home-path, cp home-files (u+w), dot-writable-sync -> ~/.config"]
        end
    end

    base_json -->|"dockerTools.pullImage"| base_layers
    base_layers -->|"extract_from_base etc/{passwd,group}"| passwd
    hm_cfg --> store_layers
    sys_cfg --> store_layers
    nix_cfg --> daemon
    sys_cfg --> daemon
    sys_cfg --> sys_etc
    hm_cfg --> hm_state
```

## Build, Distribution & Runtime Workflow

```mermaid
flowchart TD
    subgraph Update ["1. Base Image Update"]
        upd["nix run .#container-layered.passthru.updateScript (skopeo + nix-prefetch-docker)"] --> base_json["containers/base-image.json"]
    end

    subgraph Build ["2. Build & Distribution"]
        base_json --> flake_pkg[".#container-layered"]
        flake_pkg -->|"containers/build.bash (.passthru.stream | podman load)"| local_img["localhost/home:latest"]
        flake_pkg -->|"CI: .github/workflows/container.yml (push if RootFS.Layers changed)"| ghcr_img["ghcr.io/kachick/home:<tag>"]
    end

    subgraph Runtime ["3. Podman Runtime (sandbox.bash / test.bash)"]
        local_img -->|"--local (default)"| podman_run["podman run --detach --rm (PID 1: systemd --system -> nix-daemon.socket)"]
        ghcr_img -->|"--ghcr <TAG> / task ghcr"| podman_run

        podman_run -->|"containers/test.bash"| smoke["Smoke Tests (podman exec --user=user): PATH (fd), no setlocale warnings, LANG=ja_JP.UTF-8, nix store info --store daemon"]
        podman_run -->|"containers/sandbox.bash"| shell["Login Shell (podman exec --user=user): /home/user/.nix-profile/bin/bash --login"]

        live_mount["Host Repo (--live): mounted ro at /workspace/dotfiles (.env masked with /dev/null)"] -.->|"nix run /workspace/dotfiles#home-manager -- switch --flake /workspace/dotfiles#user@container"| shell
    end
```

## Build and test locally

```bash
# Update base image digest and hash in base-image.json
nix run .#container-layered.passthru.updateScript

# Build and stream-load into podman
task build-container

# Or build the compressed tarball and load with progress
nix build .#container-layered
pv result | podman load

# Run smoke tests
task test-container

# Start an interactive login shell
task sandbox

# Start with the current repo mounted read-only at /workspace/dotfiles
./containers/sandbox.bash --live
```

Inside a `--live` shell, apply working tree changes without rebuilding the image:

```bash
nix run /workspace/dotfiles#home-manager -- switch --flake /workspace/dotfiles#user@container
```
