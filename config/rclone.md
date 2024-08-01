# Rclone

Rclone enables an OSS vault on several Cloud Storages.\
And it makes it possible to use [Google Drive on Linux](https://abevoelker.github.io/how-long-since-google-said-a-google-drive-linux-client-is-coming/).

## Setup

Create new remote definition and create new vault under the remote.

For example

```json
{
  "google-drive-Foo": { "type": "drive" },
  "google-drive-Foo-Vault": {
    "remote": "google-drive-Foo:vault",
    "type": "crypt"
  }
}
```

If you are actually setting up Google Drive as this, you should get client_id and the client_secret in [Google API Console](https://console.developers.google.com/).\
See [rclone with Google Drive](https://rclone.org/drive) for detail.

[This article](https://zenn.dev/milly/books/rclone-crypt-gdrive/viewer/b366c4) also helps to setup.

## Restore Config

Assume you encrypted the config

```bash
rclone config touch
micro "$(rclone config file | tail -1)"
```

Don't save the file in this repository even if it is encrypted with agenix or sops-nix.

## Persist the token in a session

Always need the token when modifying config is too annoy.\
Now it reads from `RCLONE_PASSWORD_COMMAND`.\
Or directly set `RCLONE_CONFIG_PASS` as this.\
(`read -s` does not work in zsh)

```bash
export RCLONE_CONFIG_PASS="$(micro)"
```

## Mount

### Windows

```pwsh
winget install --exact --id WinFsp.WinFsp
rclone mount google-drive-Foo-Vault: G: --vfs-cache-mode writes --log-level INFO
```

### Linux

```bash
mount_to="$(mktemp --directory)"
echo "Mounting Google Drive on $mount_to"
rclone mount google-drive-Foo-Vault: "$mount_to" --vfs-cache-mode writes --log-level INFO
```

## GUI on Linux

See <https://github.com/germanztz/gnome-shell-extension-rclone-manager> for detail
