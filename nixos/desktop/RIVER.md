# River Tiling Window Manager

This document explains the River setup in this repository and how to develop and test it.

## Overview

The goal is to migrate step by step from the current GNOME desktop to the River tiling window manager.
To make fast iterations without breaking the host environment, River runs inside an isolated NixOS virtual machine (`river-vm`).

## Current Setup (Minimal Environment)

- **Compositor**: `river-classic` (v0.3.17)
  - Note: River v0.4+ in nixpkgs is a non-monolithic compositor without a built-in window manager. `river-classic` provides the familiar dynamic tiling compositor with `riverctl` and `rivertile`.
- **Layout Generator**: `rivertile` (outer/inner padding: 4px)
- **Terminal**: `ghostty` (same configuration as the host)
- **App Launcher**: `fuzzel` (fast Wayland native dmenu/rofi alternative)
- **Auto-login**: `greetd` automatically logs into user `kachick` and starts River.

## How to Test

### 1. Interactive Manual Testing (Graphical Window)

Run the following command to start River inside a QEMU window on your desktop:

```bash
task vm-river
```

Or run directly with Nix:

```bash
nix run .#nixosConfigurations.river-vm.config.system.build.vm
```

You can use your mouse and keyboard inside the QEMU window.

### 2. Automated Headless Verification (Screenshot)

Run the automated test script to boot River headlessly, capture a screenshot via QEMU monitor screendump, and verify rendering:

```bash
task test-river-vm
```

Or run the script directly:

```bash
./scripts/test-river-vm.bash
```

The captured screenshot is saved to `/tmp/river-screen.png`.

## Keybindings

- `Super + Return`: Open terminal (`ghostty`)
- `Super + Space`: Open app launcher (`fuzzel`)
- `Super + Q`: Close focused window
- `Super + Shift + E`: Exit River
- `Super + J` / `Super + K`: Focus next / previous window
- `Super + Shift + J` / `Super + Shift + K`: Swap window position
- `Super + Left/Right/Up/Down`: Change layout orientation (left, right, top, bottom)
- `Super + Left Click Drag`: Move floating window
- `Super + Right Click Drag`: Resize floating window

## Roadmap: Migration Steps to Replace GNOME

To reach the final goal of replacing GNOME on the host machine (`algae`), consider the following steps:

1. **Status Bar & System Tray**:
   - Add `waybar` to show tags (workspaces), clock, audio volume, and system tray.
2. **Notification Daemon & Wallpaper**:
   - Add `mako` for desktop notifications.
   - Add `swaybg` for background wallpaper.
3. **Input Method (Japanese IME)**:
   - Configure Mozc / Fcitx5 for Wayland.
4. **Screen Lock & Idle**:
   - Add `swaylock` and `swayidle`.
5. **Host Integration (`algae`)**:
   - Create a desktop module `nixos/desktop/river.nix`.
   - Enable River on `nixos/hosts/algae` alongside or in place of GNOME.
