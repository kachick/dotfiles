# vscode

## How to bulk install extensions without cloud sync

```bash
xargs --no-run-if-empty --max-lines=1 code --install-extension <./config/vscode/extensions.txt
```

This is same method as [tips](https://stackoverflow.com/a/60805086)

## How to backup the extensions

```bash
code --list-extensions | sort >./config/vscode/extensions.txt
```

## Configuration Files

These configuration files are kept in this directory for reference and manual copying:

- `settings.json` -> `~/.config/Code/User/settings.json`
- `keybindings.json` -> `~/.config/Code/User/keybindings.json`
- `argv.json` -> `~/.vscode/argv.json`

### Why Not Managed by Home Manager?

- **Direct writes**: VS Code often updates `settings.json` and `argv.json` directly. Symlinking them can lead to broken links or unexpected overwrites.
- **Portability**: VS Code is an unfree package and excluded from container or minimal environments (see `home-manager/editor.nix`).
