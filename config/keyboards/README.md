# Keyboard Configuration

This document outlines the general philosophy and platform-specific settings for keyboard remapping in this repository.

## Philosophy

As of August 2025, the goal is to minimize the use of software-based key remappers. The primary consistency target is to use `Ctrl+Space` for switching the IME (Input Method Editor) on ANSI keyboards across all platforms.

---

## Platform-Specific Settings

The only software-level modification is to disable the `CapsLock` key.

### Linux

The `CapsLock` key is disabled using `extraHwdb` definitions in NixOS. You can find these definitions by [searching the repository](https://github.com/search?q=repo%3Akachick%2Fdotfiles+extraHwdb&type=code). All other software-based key remappers have been removed.

### Windows

The `CapsLock` key is disabled using [Keyboard Manager](https://github.com/microsoft/PowerToys), which is part of Microsoft PowerToys.

### macOS

The `CapsLock` key is disabled using the built-in keyboard remapping feature in System Settings.

---

## Hardware-Level Customization (QMK)

These notes apply to QMK-compatible keyboards like Keychron.

### Flashing Firmware

The firmware can be customized and flashed by importing a JSON configuration file via the [Keychron Launcher](https://launcher.keychron.com/) (tested on Windows).

### Firmware Schema Notes

- My current device is a Keychron V3 Max (JIS layout).
- The official [QMK firmware repository](https://github.com/qmk/qmk_firmware/tree/master/keyboards/keychron) has definitions for the standard V3 line, but not specifically for the "Max" variant. The standard [V3 JIS definition](https://github.com/qmk/qmk_firmware/tree/782f91a73a0f6d4128f9454509b4a207af269f8b/keyboards/keychron/v3/jis) is used as a base.
