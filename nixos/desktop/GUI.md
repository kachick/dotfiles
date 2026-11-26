# GUI

## GNOME

Q: How to reload GNOME on wayland settings without reboot?\
A: [`SUPER+L`](https://superuser.com/a/1740160)

Q: How to check current settings?\
A: Use `gsettings` or [`dconf-editor`](https://wiki.nixos.org/wiki/GNOME)

```bash
gsettings get org.gnome.desktop.lockdown disable-lock-screen
gsettings list-recursively org.gnome.shell.keybindings | fzf
```

Q: How to persist this config from settings menu?\
A: `dconf watch /`

Q: Why default-apps changes will not be appeared in dconf watch?\
A: Use `xdg.mimeApps` module in home-manager

Q: [Broken cursor as white square](https://github.com/NixOS/nixpkgs/issues/140505#issuecomment-1637341617)\
A: `dconf reset /org/gnome/desktop/interface/cursor-theme`

## IME

Don't use fcitx5. It causes crashes. See GH-1128 for details.

Home Manager generates and syncs `~/.config/mozc/config1.db` from `config/mozc/keymap-msime-customized.txt` via `mozc-config`, so manual GUI keymap import is no longer needed.
Run `mozc-config diff` to inspect local GUI changes against the generated config, or `mozc-config reload` to refresh IBus and `mozc_server`.

## KDE

The definition will be recorded in `~/.config/kglobalshortcutsrc`, however editing and managing by hand is a hard thing.
