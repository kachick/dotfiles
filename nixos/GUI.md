# GUI

Started from KDE for the battery-included and stable behaviors.\
However I need tilling window manager for several reasons, especially unstable wezterm and zelliji cannot define multiple modifier.\
So I started to using Hyprland. This maybe the note.

=> And switched to GNOME

## GNOME

Q: How to reload GNOME on wayland settings without reboot?\
A: [`SUPER+L`](https://superuser.com/a/1740160)

Q: How to check current settings?\
A: `gsettings get org.gnome.desktop.lockdown disable-lock-screen`

Q: How to persist this config from settings menu?
A: `dconf watch /`

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

For Nix managing configurations, seprarwly having local file should be helpful for develop.

```bash
touch ~/.config/hypr/local.conf
```

And comment-out the `source = ~/.config/hypr/local.conf` in your config
