# Background Daemon and SSH Execution for `microvm-sandbox`

## Goal

Extend `microvm-sandbox` so multiple isolated NixOS instances can run in the background and accept non-interactive commands or interactive shells over SSH, while keeping the current foreground serial console mode (`microvm-sandbox` with no arguments) working as before.

## Current Architecture

- [nixos/hosts/sandbox/default.nix](../nixos/hosts/sandbox/default.nix) defines a QEMU-based NixOS microvm that mounts host `/nix/store` (read-only + tmpfs overlay), `/run/current-system/sw`, and `/home/kachick/repos/github.com/kachick` via 9p.
- [flake.nix](../flake.nix) wraps `nixosConfigurations.sandbox.config.microvm.declaredRunner` (`/bin/microvm-run`) into `packages.x86_64-linux.microvm-sandbox`.
- Currently, `services.openssh.enable = false;` is set, and `microvm-run` attaches QEMU serial stdio directly to the current terminal (`-chardev stdio,id=stdio,signal=off -serial chardev:stdio`) with `netdev user,id=net0`.

## Why Change

Foreground serial stdio only supports one interactive session tied to a single terminal. Coding agents and parallel testing workflows need to:

1. Start one or more named sandbox instances in the background (`up`).
2. Run non-interactive commands and receive exit codes and output cleanly (`exec`).
3. Open interactive SSH sessions without serial line-wrapping issues (`ssh`).
4. Stop and clean up instances reliably (`down`, `status`).

## Design Specification

### 1. Guest NixOS Configuration (`nixos/hosts/sandbox/default.nix`)

1. Enable OpenSSH for passwordless login by `user`:
   - Set `services.openssh.enable = true;`.
   - Set `services.openssh.settings.PermitEmptyPasswords = "yes";` and `services.openssh.settings.PasswordAuthentication = true;` (or mount/accept a host runtime public key).
   - Keep `security.pam.services.sshd.allowNullPassword = true;` alongside `security.pam.services.login.allowNullPassword = true;`.
   - Because QEMU SLiRP (`type = "user"`) only forwards localhost ports explicitly specified via `hostfwd=tcp:127.0.0.1:<PORT>-:22`, guest port 22 is never exposed outside `127.0.0.1` on the host.
2. Ensure SSH is ready after `sync-user-uid.service` and `home-manager-user.service`:
   - Order `sshd.service` after `sync-user-uid.service` so UID changes do not race with incoming SSH logins.

### 2. Multi-Instance CLI Wrapper (`flake.nix` or `pkgs/by-name/mi/microvm-sandbox/package.nix`)

Replace the simple symlink in `flake.nix` with a shell application (`pkgs.writeShellApplication`) that wraps `${outputs.nixosConfigurations.sandbox.config.microvm.declaredRunner}/bin/microvm-run`.

#### Subcommands

- `microvm-sandbox` (or `microvm-sandbox console`):
  - Run the original `microvm-run` in the foreground on the serial console (backwards compatible).
- `microvm-sandbox up [NAME]` (default `NAME`: `default`):
  - State directory: `${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/microvm-sandbox/${NAME}`.
  - If `qemu.pid` exists and the process is alive, print status and exit `0`.
  - Find an unused local TCP port on `127.0.0.1` (for example by probing ports starting from `2221` or binding an ephemeral socket).
  - Read `${declaredRunner}/bin/microvm-run` or copy and patch the QEMU invocation for daemon mode:
    - Replace `-chardev 'stdio,id=stdio,signal=off'` and `-serial chardev:stdio` with `-serial "file:${STATE_DIR}/console.log"` and `-daemonize -pidfile "${STATE_DIR}/qemu.pid"`.
    - Replace `-netdev 'user,id=net0'` with `-netdev "user,id=net0,hostfwd=tcp:127.0.0.1:${PORT}-:22"`.
    - Replace `-name sandbox` with `-name "sandbox-${NAME}"`.
  - Save `${PORT}` to `${STATE_DIR}/ssh.port`.
  - Wait until SSH on `127.0.0.1:${PORT}` accepts a connection (`ssh -p "$PORT" user@127.0.0.1 true`) with a timeout (e.g. 30 seconds).
- `microvm-sandbox exec [NAME] -- <COMMAND...>` (or `microvm-sandbox exec -- <COMMAND...>` targeting `default`):
  - Read `${STATE_DIR}/ssh.port`.
  - Execute `ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -p "$PORT" user@127.0.0.1 -- "$@"`.
- `microvm-sandbox ssh [NAME]`:
  - Open an interactive SSH login shell to `127.0.0.1:${PORT}` as `user`.
- `microvm-sandbox status`:
  - List all directories under `${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/microvm-sandbox/`, check if `qemu.pid` is alive, and print instance name, PID, and SSH port.
- `microvm-sandbox down [NAME|--all]`:
  - Send `SIGTERM` to the PID in `qemu.pid` (falling back to `SIGKILL` after a short wait) and remove `${STATE_DIR}`.

## Implementation Steps

1. Edit [nixos/hosts/sandbox/default.nix](../nixos/hosts/sandbox/default.nix):
   - Enable `services.openssh` with null password login on `127.0.0.1` forwarded ports.
   - Add `systemd.services.sshd.after = [ "sync-user-uid.service" "home-manager-user.service" ];` and `wants = [ "sync-user-uid.service" ];`.
2. Implement the wrapper script in [flake.nix](../flake.nix) (or extract to a script under `nixos/hosts/sandbox/` referenced by `flake.nix`).
3. Update [nixos/hosts/sandbox/README.md](../nixos/hosts/sandbox/README.md) (if present) or root documentation with usage examples for `up`, `exec`, `ssh`, `status`, and `down`.

## Verification Checklist

1. Build check:
   - `nix build .#nixosConfigurations.sandbox.config.system.build.toplevel --dry-run`
   - `nix build .#microvm-sandbox --no-link`
2. Runtime test (requires `BypassSandbox: true` for `/dev/kvm`):
   - `nix run .#microvm-sandbox -- up test-1`
   - `nix run .#microvm-sandbox -- up test-2`
   - `nix run .#microvm-sandbox -- status` (confirm both instances run on different ports)
   - `nix run .#microvm-sandbox -- exec test-1 -- hostname`
   - `nix run .#microvm-sandbox -- exec test-2 -- which rg`
   - `nix run .#microvm-sandbox -- down --all`
3. Repository linters:
   - `task fmt`
   - `task lint-all`
   - `task test-go`
