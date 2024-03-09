## How to build and test in local

```bash
podman build --tag nix-systemd --file containers/Containerfile .
podman run --rm localhost/nix-systemd:latest &
sleep 1
container_name="$(podman ps --sort=created --format {{.Names}} | tail -1)"
[ -n "$container_name" ]
podman exec --user=user -it "$container_name" /provisioner/needs_systemd.bash
podman exec --user=root -it "$container_name" rm -rf /provisioner/cleanup.bash
podman commit "$container_name" provisioned-systemd-home
podman kill "$container_name"
```

Since now, we can reuse the image as this

```bash
podman run --rm localhost/provisioned-systemd-home &
sleep 1
container_name="$(podman ps --sort=created --format {{.Names}} | tail -1)"
[ -n "$container_name" ]
podman exec --user=user --workdir='/home/user' -it "$container_name" /home/user/.nix-profile/bin/zsh

# You can use the container here
# ~ zsh
# > la --tree .config
# drwxr-xr-x - user  9 Mar 00:31 .config
# drwxr-xr-x - user  9 Mar 00:31 ├── alacritty

podman kill "$container_name"
```
