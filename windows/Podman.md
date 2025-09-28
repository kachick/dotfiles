# Podman on Windows Guide

This document provides a collection of solutions and tips for using Podman on Windows, often in conjunction with WSL.

---

## Troubleshooting and Solutions

### `WARN[0000] "/" is not a shared mount`

This warning can appear with rootless containers and may cause issues with volume mounts.

- **Context:** See [buildah issue #3726](https://github.com/containers/buildah/issues/3726#issuecomment-1171146242).
- **Solution:** Run the following command in your WSL distribution to change the mount propagation:

  ```bash
  sudo mount --make-rshared /
  ```

### Podman 5.x Upgrade Issues

After a major upgrade (e.g., from 4.x to 5.0.0), you might encounter errors due to breaking changes in the machine configuration format.

- **Symptom:** Errors like `json: cannot unmarshal string into Go struct field MachineConfig.ImagePath`.
- **Context:** See [podman issue #22144](https://github.com/containers/podman/issues/22144). This may happen again in future major updates.
- **Solution:** The following steps will completely reset your Podman environment, **deleting all existing VMs, images, and containers.**

  ```powershell
  # Uninstall Podman and Podman Desktop
  winget uninstall --exact --id RedHat.Podman-Desktop
  winget uninstall --exact --id RedHat.Podman

  # Unregister the Podman machine from WSL
  wsl --list
  wsl --unregister podman-machine-default

  # Clean up remaining machine files
  cd "$env:USERPROFILE\.config\containers\podman\machine\wsl"
  Remove-Item .\podman-machine-*

  # Reinstall Podman and Podman Desktop
  winget install --exact --id RedHat.Podman
  winget install --exact --id RedHat.Podman-Desktop
  ```
  After reinstalling, you will need to create a new Podman machine.

---

## Advanced Usage and Tips

### Mounting Project Volumes for Remote Podman

Currently, there is no simple, direct way to mount host volumes when using a remote Podman client. This repository uses a workaround by mounting the WSL instance's filesystem into the Podman machine.

1. **Enable Mounts in Ubuntu:**
   Activate the Home Manager configuration for `kachick@wsl-ubuntu`. The [WSL definitions](../home-manager/wsl.nix) include systemd units to handle the necessary mounts.

2. **Verify Access from Podman Machine:**
   Ensure the Podman machine can access the mounted filesystem. For example:
   `ls /mnt/wsl/instances/ubuntu24/home`

3. **Run a Container with Mounted Volume:**
   From your Ubuntu WSL instance, navigate to your project directory and run a container, mounting the current path.

   ```bash
   # In the Ubuntu WSL instance
   cd /path/to/your/project
   podman run -v "/mnt/wsl/instances/ubuntu24/$(pwd):/workdir" -it ghcr.io/ruby/ruby:latest
   ```

### SSH Access to the Podman Machine

You can set up SSH access to the Podman machine from another WSL instance (e.g., Ubuntu).

1. **Copy Public Key (from Ubuntu):**
   Copy your SSH public key to the clipboard.

   ```bash
   cat ~/.ssh/id_ed25519.pub | clip.exe
   ```

2. **Authorize Key (in Podman Machine):**
   Paste the copied key into the `~/.ssh/authorized_keys` file inside the Podman machine.

   ```bash
   # In the Podman machine shell
   vi ~/.ssh/authorized_keys
   ```

3. **Find SSH Port (on Windows Host):**
   Use PowerShell to find the port number for the Podman machine's SSH connection.

   ```powershell
   podman system connection list | Select-String 'ssh://\w+@[^:]+:(\d+)' | ForEach-Object { $_.Matches.Groups[1].Value }
   ```

4. **Connect via SSH (from Ubuntu):**
   Use the port number you found to SSH into the Podman machine.

   ```bash
   # Example using port 53061
   ssh user@localhost -p 53061
   ```

### Mounting Client Volumes with `rclone`

After setting up SSH access, you can use `rclone` to mount a directory from the Podman machine onto your client WSL instance.

1. **Configure `rclone` (in Ubuntu):**
   Create a new `rclone` remote for the Podman machine.

   ```bash
   rclone config create podman-machine sftp host=localhost port=53061 user=user key_file=~/.ssh/id_ed25519
   # Verify the connection
   rclone lsd podman-machine:/home/user
   ```

2. **Mount the Directory:**
   Navigate to your project directory and use `rclone mount` to mount the corresponding remote directory.

   ```bash
   cd /path/to/your/project
   rclone mount --daemon "podman-machine:repos/$(basename "$(pwd)")" .
   ```

3. **Unmounting:**
   To unmount the directory, use `fusermount`.

   ```bash
   fusermount -u /path/to/your/project
   ```

### One-Shot Sync with `rclone`

As an alternative to mounting, you can use `rclone sync` for a one-time synchronization of your project files to the Podman machine.

```bash
# In the Ubuntu WSL instance
cd /path/to/your/project
rclone sync --progress . "podman-machine:repos/$(basename "$(pwd)")"
```
