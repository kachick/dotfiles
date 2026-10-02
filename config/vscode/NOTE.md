# Notes on Wayland Flags and Warnings in VS Code

## The Problem

When running `code .` from a terminal on NixOS with Wayland, VS Code prints these warnings:

```console
$ code .
Warning: 'ozone-platform-hint' is not in the list of known options, but still passed to Electron/Chromium.
Warning: 'enable-features' is not in the list of known options, but still passed to Electron/Chromium.
Warning: 'enable-wayland-ime' is not in the list of known options, but still passed to Electron/Chromium.
Warning: 'wayland-text-input-version' is not in the list of known options, but still passed to Electron/Chromium.
```

VS Code still opens, but the warnings make terminal output noisy.

## Why This Happens (Root Causes)

1. **Nixpkgs wrapper adds flags automatically**:
   In NixOS, when `NIXOS_OZONE_WL = "1"` is set, the Nixpkgs package wrapper (`generic.nix`) adds these flags to `bin/code`:
   `--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true --wayland-text-input-version=3`.

2. **VS Code CLI checks for known options**:
   When you run `code`, it runs a Node.js CLI script (`resources/app/out/cli.js`).
   This CLI script has a list of known options like `--diff` and `--wait`.
   Because Chromium and Electron flags are not in this list, the CLI script prints a warning before passing them to Electron.

3. **`argv.json` ignores unknown flags**:
   VS Code has a runtime file (`~/.vscode/argv.json`).
   However, its main process (`main.js`) only reads a few fixed keys like `password-store` and `disable-hardware-acceleration`.
   Flags like `ozone-platform-hint` are not in its allow-list and are ignored.

4. **`electron-flags.conf` is not read by VS Code**:
   VS Code does not look for `~/.config/electron-flags.conf`.
   Only external wrappers on distributions like Arch Linux do that.

## Current State in Modern Electron (Electron 38+)

- **Wayland is now the default in Electron 38+**:
  Recent VS Code (1.119+) uses Electron 39+.
  Starting from Electron 38, `--ozone-platform` defaults to `auto`.
  Electron automatically detects Wayland without `--ozone-platform-hint=auto`.
  The old environment variable `ELECTRON_OZONE_PLATFORM_HINT` was also removed.
- **IME flag is still experimental**:
  `--enable-wayland-ime=true` is still not enabled by default in Chromium.
  It is still needed in some cases for Japanese input (IBus / Fcitx5) on Wayland.
- **`password-store` has official support in `argv.json`**:
  You can set `"password-store": "gnome-libsecret"` inside `~/.vscode/argv.json`.
  You do not need to pass it as a command line flag.

## Possible Solutions

### Approach 1: Shell wrapper for CLI (Recommended)

When you run `code .` from a terminal:

- If VS Code is already running, the CLI just tells the existing window to open the folder using IPC. Wayland flags do nothing here.
- If VS Code is not running yet, Electron 39+ detects Wayland automatically.

Add this function to your shell configuration (e.g. bash, zsh, or nushell):

```bash
code() {
	NIXOS_OZONE_WL= command code "$@"
}
```

- **Pros**:
  - No need to rebuild NixOS.
  - Clears all CLI warnings immediately.
  - Desktop entries (`.desktop`) still run with `NIXOS_OZONE_WL=1`, keeping IME flags intact.

### Approach 2: Use Plain `pkgs.vscode` Without Overrides

In `nixos/desktop/unfree.nix`, `vscode` previously used both `vscode.override` and `overrideAttrs`. Both are no longer needed:

1. `commandLineArgs`:
   - `--wayland-text-input-version=3` was redundant because Nixpkgs `generic.nix` already adds it when `NIXOS_OZONE_WL` is set.
   - `--password-store=gnome-libsecret` can be set in `~/.vscode/argv.json` (see template in `config/vscode/argv.json`).
2. `overrideAttrs` (`runtimeDependencies` with `libsecret`):
   - Redundant because Nixpkgs `generic.nix` has included `libsecret` in `runtimeDependencies` by default since August 2023 (commit `ed2f5f18292f`).

Therefore, `nixos/desktop/unfree.nix` can simply use plain `vscode`.

### Approach 3: Override the Nixpkgs wrapper

You can use `vscode.overrideAttrs` in Nix to replace `preFixup` and remove the automatic `--add-flags`.

- **Note**: Need to verify if Japanese input (IME) still works without `--enable-wayland-ime=true` when launched from the desktop.
