# Containers

Base images are maintained in [another repository](https://github.com/kachick/containers)

## How to build and test in local

```bash
podman build --tag nix-systemd --file containers/Containerfile .
container_id="$(podman run --detach --rm localhost/nix-systemd:latest)"
podman exec --user=user -it "$container_id" /provisioner/needs_systemd.bash
podman exec --user=root -it "$container_id" rm -rf /provisioner
podman commit "$container_id" provisioned-systemd-home
podman kill "$container_id"
```

Since now, we can reuse the image as this

```bash
container_id="$(podman run --detach --rm localhost/provisioned-systemd-home)"
podman exec --user=user --workdir='/home/user' -it "$container_id" /home/user/.nix-profile/bin/zsh

# You can use the container here
# ~ zsh
# > la --tree .config
# drwxr-xr-x - user  9 Mar 00:31 .config
# drwxr-xr-x - user  9 Mar 00:31 ├── alacritty

podman kill "$container_id"
```
