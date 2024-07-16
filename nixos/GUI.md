# GUI

Started from KDE for the battery-included and stable behaviors.\
However I need tilling window manager for several reasons, especially unstable wezterm and zelliji cannot define multiple modifier.\
So I started to using Hyprland. This maybe the note.

## KDE

The shortcut of Meta+Q conflicts to Hyprland exec terminal. Disable from system settings.\
The definition will be recorded in `~/.config/kglobalshortcutsrc`, however editing and managing by hand is a hard thing.

## Hyprland

Simple and reminderable keybinds, but empty config by default. We should set many things.

How to execute

```bash
Hyprland
```

Config

`~/.config/hypr/hyprland.conf`

Enabling by NixOS module is required, but setting by home-manager should be considered.

waybar is another tool, we should seprately install
