# Lima

Lima templates and host defaults in this directory are linked to `~/.lima/` by [home-manager/lima-host.nix](../../home-manager/lima-host.nix).

## 1. Base Environment Setup

1. Create the clean base instance with Nix and Home Manager, then stop it:

   ```bash
   limactl start --name=docker-nix-clean template:docker-nix
   limactl stop docker-nix-clean
   rm -rf ~/.lima/docker-nix-clean/sock # Avoid a Lima bug where empty sock dir causes permission warnings in clones
   ```

   - Host `~/repos/github.com/kachick` is mounted without mounting `$HOME` (keeping SSH, GPG, and secrets isolated).
   - When `~/repos/github.com/kachick/dotfiles` exists on the host, the VM automatically provisions using the local working copy (reflecting current branch and edits).

1. Clone and start the standard `docker-nix` instance for daily use:

   ```bash
   limactl clone docker-nix-clean docker-nix --start
   ```

   - `docker-nix` is configured to autostart with user sessions.
   - Run containers:

     ```bash
     limactl shell docker-nix docker run --rm hello-world
     ```

## 2. Disposable Sandbox (Suitable for AI Agents and Experiments)

Clone a quick sandbox instance from `docker-nix-clean` for safe experiments:

1. Clone and start a sandbox instance:

   - **Standard Sandbox** (Mounts `~/repos/github.com/kachick` like base):

     ```bash
     INSTANCE="sandbox-$(head -c 16 /dev/urandom | sha256sum | cut -c1-4)"
     limactl clone docker-nix-clean "$INSTANCE" --start
     ```

   - **Strict Project Isolation** (Mounts only current directory without other repos):

     ```bash
     INSTANCE="sandbox-$(head -c 16 /dev/urandom | sha256sum | cut -c1-4)"
     limactl clone docker-nix-clean "$INSTANCE" --mount-only .:w --start
     ```

     Pass additional `--mount-only /path:w` flags to attach other directories (do not use `--mount`, as it conflicts with `--mount-only`).

1. Work inside the sandbox:

   ```bash
   lima --instance "$INSTANCE"
   ```

1. Destroy when done:

   ```bash
   limactl delete -f "$INSTANCE"
   ```

## Windows on Lima

Check [latest instruction](https://github.com/lima-vm/lima/blob/master/templates/windows-11.yaml) for Windows guests.\
To use `windows-11` rather than `windows-2025`, manually download the **"English ISO file"** from [Microsoft](https://www.microsoft.com/en-us/software-download/windows11).
