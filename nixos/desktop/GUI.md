# NixOS GUI Guide

This document provides a collection of tips and troubleshooting steps for various GUI components on NixOS.

---

## GNOME

### How can I reload GNOME Shell (on Wayland) without rebooting?

Press `Alt+F2`, type `r`, and press `Enter`. If that doesn't work, locking the screen (`Super+L`) and unlocking can also sometimes apply new settings. See [this Super User answer](https://superuser.com/a/1740160) for context.

### How can I inspect current GNOME settings?

You can use the command-line tool `gsettings` or the graphical [`dconf-editor`](https://wiki.nixos.org/wiki/GNOME).

```bash
# Get a specific setting value
gsettings get org.gnome.desktop.lockdown disable-lock-screen

# Interactively search all keybindings
gsettings list-recursively org.gnome.shell.keybindings | fzf
```

### How can I find the `dconf` key for a setting changed in the GUI?

Use `dconf watch /` in a terminal. It will monitor and print any `dconf` changes as you make them in the GNOME Settings application.

### Why don't default application changes appear in `dconf watch`?

Default application associations (MIME types) are not handled by `dconf`. To manage them declaratively, use the `xdg.mimeApps` module in Home Manager.

### How do I fix a broken or white square cursor?

This can sometimes be fixed by resetting the cursor theme setting. See [nixpkgs issue #140505](https://github.com/NixOS/nixpkgs/issues/140505#issuecomment-1637341617) for details.

```bash
dconf reset /org/gnome/desktop/interface/cursor-theme
```

---

## Input Method Editor (IME)

### `fcitx5` vs. `IBus`

`fcitx5` is not recommended as it has caused system crashes in the past. `IBus` with Mozc is the preferred setup. See [issue #1128](https://github.com/kachick/dotfiles/issues/1128) for details.

### Mozc Keybindings

Mozc does not support importing custom keybinding configurations via the command line. When setting up a new desktop environment, you must import them manually through the Mozc settings GUI.

---

## KDE Plasma

While KDE Plasma settings are stored in files like `~/.config/kglobalshortcutsrc`, managing them declaratively or by hand is difficult. For this reason, GNOME is the primary desktop environment used in this repository.
