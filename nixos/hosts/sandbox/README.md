# MicroVM Sandbox

Lightweight, volatile NixOS microvm built with [microvm.nix](https://github.com/microvm-nix/microvm.nix) and QEMU.

```bash
# Foreground serial console (autologin as user)
nix run .#microvm-sandbox

# Background instances over SSH (pubkey auth via config/ssh/keys.nix)
nix run .#microvm-sandbox -- up test-1
nix run .#microvm-sandbox -- status
nix run .#microvm-sandbox -- exec test-1 -- hostname
nix run .#microvm-sandbox -- ssh test-1
nix run .#microvm-sandbox -- down test-1
nix run .#microvm-sandbox -- down --all
```

- `/home/user/repos/github.com/kachick` is shared read-write with the host.
- `/nix/store` uses a volatile `tmpfs` overlay (`2G`) and resets on shutdown.
- Background SSH logins require a local private key or `ssh-agent` matching `config/ssh/keys.nix`.

## Architecture (`default.nix`)

```mermaid
flowchart TD
    subgraph Host ["Host Machine"]
        host_store["/nix/store (ro)"]
        host_sw["/run/current-system/sw (ro)"]
        host_repos["/home/kachick/repos/github.com/kachick (rw)"]
        host_dns["Host DNS Proxy (:5354, optional)"]
        host_ssh["ssh client + ssh-agent (config/ssh/keys.nix)"]
    end

    subgraph Guest ["QEMU MicroVM (sandbox, 4 vCPU, 4G RAM, SLiRP net0)"]
        ro_store["/nix/.ro-store (9p) + /nix/.rw-store (2G tmpfs) -> /nix/store"]
        guest_sw["/run/host-system-sw (9p, appended to PATH)"]
        guest_repos["/home/user/repos/github.com/kachick (9p)"]

        subgraph Boot ["Systemd Boot Order"]
            uid["sync-user-uid.service (match guest UID to host repos)"]
            hm["home-manager-user.service (ephemeral + dev + containers)"]
            sshd["sshd.service (PasswordAuthentication=no, keys.nix)"]
            getty["serial-getty@ (autologin user)"]
            dns["sandbox-host-dns.service (DNAT gw:53 -> gw:5354 if open)"]
        end
    end

    host_store -->|"9p ro-store"| ro_store
    host_sw -->|"9p host-sw"| guest_sw
    host_repos -->|"9p repos"| guest_repos
    uid --> hm
    hm --> sshd
    hm --> getty
    host_ssh -->|"hostfwd 127.0.0.1:<PORT> -> :22"| sshd
    dns -.->|"probe & forward"| host_dns
```

## CLI & Lifecycle (`microvm-sandbox.bash`)

```mermaid
flowchart TD
    cli["microvm-sandbox (package.nix -> writeShellApplication)"]

    cli -->|"no args / console"| fg["exec declaredRunner/bin/microvm-run (foreground stdio)"]

    cli -->|"up [NAME]"| up["Patch microvm-run & pick free port (2221-2320)"]
    up --> state["$XDG_RUNTIME_DIR/microvm-sandbox/<NAME>/{microvm-run,qemu.pid,ssh.port,console.log}"]
    state -->|"QEMU -daemonize + hostfwd"| wait["Poll SSH (BatchMode=yes, timeout 30s)"]

    cli -->|"exec [NAME] -- <CMD>"| exec_cmd["ssh -o BatchMode=yes -o ControlMaster=no user@127.0.0.1 -- <CMD>"]
    cli -->|"ssh [NAME]"| ssh_cmd["Interactive ssh -o ControlMaster=no user@127.0.0.1"]
    cli -->|"status"| status_cmd["Read qemu.pid & ssh.port under state dir"]
    cli -->|"down [NAME|--all]"| down_cmd["SIGTERM -> SIGKILL QEMU & remove state dir"]

    state -.-> exec_cmd
    state -.-> ssh_cmd
    state -.-> status_cmd
    state -.-> down_cmd
```

## Why not nixos-shell?

Evaluated [nixos-shell](https://github.com/Mic92/nixos-shell) as of 2026-11. Revisit if these points change:

- Broken on `nixos-unstable`: `2.2.0` in nixpkgs references removed `boot.initrd.systemd.enable`, and `main` fails to replace `--cache=always` in `run-nixos-vm` after the `run-virtiofsd-qemu` change.
- Depends directly on `qemu-vm.nix` runner script text, so upstream `nixpkgs` updates break it easily.
- Defaults to root autologin, full `$HOME` mount, and `.qcow2` disk files in the working directory instead of a volatile, scoped sandbox.
- Existing host configs (such as `moss`) hit host-specific checks like `zswap` without extra overrides.
