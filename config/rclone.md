# Using Rclone for Encrypted Cloud Storage

This guide explains how to use Rclone to create an encrypted "vault" on various cloud storage services. This setup allows for secure, cross-platform access to your files, including using Google Drive on Linux without relying on `gnome-online-accounts`.

---

## Initial Setup

The basic idea is to create a standard remote for your cloud provider and then layer an encrypted "crypt" remote on top of it.

### Example Configuration

Here is an example of a `crypt` remote (`google-drive-Foo-Vault`) layered on top of a standard `drive` remote (`google-drive-Foo`).

```json
{
  "google-drive-Foo": { "type": "drive" },
  "google-drive-Foo-Vault": {
    "remote": "google-drive-Foo:vault",
    "type": "crypt"
  }
}
```

- **Google Drive Specifics:** If you are setting this up with Google Drive, you must obtain a `client_id` and `client_secret` from the [Google API Console](https://console.developers.google.com/). For detailed instructions, refer to the official [Rclone with Google Drive](https://rclone.org/drive/) documentation.
- **Further Reading (Japanese):** [This article](https://zenn.dev/milly/books/rclone-crypt-gdrive/viewer/b366c4) also provides a helpful guide for this setup.

### Configuration File Security

**Do not commit your Rclone configuration file to this repository**, even if it is encrypted with tools like `agenix` or `sops-nix`. The password for the configuration file itself should be managed separately.

See the [Encryption wiki page](https://github.com/kachick/dotfiles/wiki/Encryption) for details on the recommended secret management strategy. The Rclone password should be injected at runtime using the `RCLONE_PASSWORD_COMMAND` environment variable.

---

## Mounting the Encrypted Vault

### On Windows

1. Install WinFsp to enable filesystem mounting.
   ```powershell
   winget install --exact --id WinFsp.WinFsp
   ```
2. Mount the vault.
   ```powershell
   rclone mount google-drive-Foo-Vault: G: --vfs-cache-mode writes --log-level INFO
   ```

### On Linux

1. Create a temporary mount point and mount the vault.
   ```bash
   mount_to="$(mktemp --directory)"
   echo "Mounting vault on $mount_to"
   rclone mount google-drive-Foo-Vault: "$mount_to" --vfs-cache-mode writes --log-level INFO
   ```
2. **Note on Automation:** This repository avoids using systemd for mounting to prevent storing secrets directly in configuration files. Instead, use the `rclone-fzf` helper script for interactive mounting.

### On macOS

Rclone is not actively used in the macOS environment for this project. See issues [GH-911](https://github.com/kachick/dotfiles/issues/911) and [GH-1016](https://github.com/kachick/dotfiles/issues/1016) for context.

---

## GUI Clients on Linux

Using a GUI wrapper like the [rclone-manager GNOME extension](https://github.com/germanztz/gnome-shell-extension-rclone-manager) is **not recommended** with this encrypted setup. The extension's method of handling passwords (e.g., `echo PASS`) is insecure and incompatible with the `RCLONE_PASSWORD_COMMAND` approach used here.
