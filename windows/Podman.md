# Podman

## How to resolve `WARN[0000] "/" is not a shared mount, this could cause issues or missing mounts with rootless containers`

See <https://github.com/containers/buildah/issues/3726#issuecomment-1171146242>

```bash
sudo mount --make-rshared /
```

## How to install

Use one of following.

- Directly Install podman into the debian family # Now using. The whole steps are written in [README](../README.md) and [WSL](WSL/README.md)
- [Install podman-desktop](./Podman-Remote.md), it easy to install but requires annoy setups with another WSL instance. # Old way, Written in this file

It needs special WSL distribution. How to run it from standard WSL ubuntu is written in [this document](https://podman-desktop.io/docs/podman/accessing-podman-from-another-wsl-instance).\
Make sure you are using podman binary as podman-remote, nixpkgs product does not satisfy.\
This repository aliases podman command to mise installed binary.

This is an worked example

```bash
# WSL - Ubuntu

podman system connection add --default podman-machine-default-user unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-user.sock

# Since Ubuntu 24.04, you may need to update the usergroup of socket file
sudo chgrp "$(whoami)" /mnt/wsl/podman-sockets/podman-machine-default/podman-user.sock

# See wsl.nix for detail
# TODO: Update cmd/wsl-init
sudo systemctl enable ~/.config/systemd/user/mnt-wsl-instances-ubuntu24.mount --now

cdg irb-power_assert
podman run --volume /mnt/wsl/instances/ubuntu24/"$(pwd)":/workdir --workdir /workdir -it ghcr.io/ruby/ruby:master-dev-jammy-amd64-da66abc584a9a33693d1b5bbf70881a008b0935d
```

## After updating podman from 4.x -> 5.0.0, cannot do any operation even if the setup VM

```plaintext
Error: Command execution failed with exit code 125 Command execution failed with exit code 125 Error: unable to load machine config file: "json: cannot unmarshal string into Go struct field MachineConfig.ImagePath of type define.VMFile"
```

It relates to [podman#22144](https://github.com/containers/podman/issues/22144).\
And might be happen in future major updating and the schema changes. So this snippet may help you.

Abandon current VM, images, containers. Then following steps are the how to fix

```pwsh
winget uninstall --exact --id RedHat.Podman-Desktop
winget uninstall --exact --id RedHat.Podman
wsl --list
wsl --unregister podman-machine-default
cd ${Env:USERPROFILE}\.config\containers\podman\machine\wsl\
Remove-Item .\podman-machine-*
winget install --exact --id RedHat.Podman
winget install --exact --id RedHat.Podman-Desktop
```

And create the new podman-machine-default

## How mount project volumes in podman-remote

Track the [official discussion](https://github.com/containers/podman/discussions/13537), but there are no simple solutions for now.\
This repository provides a mount based solution, mount from another instance as /mnt/wsl/..., then podman-machine also can access there.

1. Ubuntu: Activate the home-manager with `--flake '.#kachick@wsl-ubuntu'`.
2. Look the [definitions](../../home-manager/wsl.nix), it includes how to mount with systemd.
3. podman-machine: Make sure podman-machine can read there `ls /mnt/wsl/instances/ubuntu24/home`
4. Ubuntu: `cdg project_path`
5. Ubuntu: `podman run -v /mnt/wsl/instances/ubuntu24/"$(pwd)":/workdir -it ghcr.io/ruby/ruby:master-dev-76732b3e7b42d23290cd96cd695b2373172c8a43-jammy`

## How SSH login to podman-machine from another WSL instance like default Ubuntu?

1. WSL - Ubuntu

   Get pubkey

   ```bash
   <~/.ssh/id_ed25519.pub | clip.exe
   ```

2. WSL - podman-machine

   Register the Ubuntu pubkey

   ```bash
   vi ~/.ssh/authorized_keys
   ```

3. Host - Windows

   Get podman-machine port number

   ```pwsh
   podman system connection list | Select-String 'ssh://\w+@[^:]+:(\d+)' | % { $_.Matches.Groups[1].Value }
   ```

4. WSL - Ubuntu

   You can login with the port number, for example 53061

   ```bash
   ssh user@localhost -p 53061
   ```

## How mount client volume with podman-remote

After SSH setup as above steps

In WSL - Ubuntu

```bash
rclone config create podman-machine sftp host=localhost port=53061 publickey=~/.ssh/id_ed25519.pub user=user
# Make sure the connection
rclone lsd podman-machine:/home/user

z project_path 
rclone mount --daemon "podman-machine:repos/$(basename "$(pwd)")" .

# If you want to unmount, use specific command instead of kill the background job
# 
# Linux
fusermount -u /path/to/local/mount
# OS X
# umount /path/to/local/mount
```

## How oneshot sync source code for podman-remote

This is just a note, prefer `rclone mount` for easier

After SSH setup as above steps

In WSL - Ubuntu

```bash
z project_path

rclone sync --progress . "podman-machine:repos/$(basename "$(pwd)")"
```
