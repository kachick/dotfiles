# Development Containers

The base images for these containers are maintained in the [kachick/containers](https://github.com/kachick/containers) repository.

## Local Build and Test Workflow

This section describes how to build the container images locally for testing purposes.

### 1. Build the Base Image

First, build the initial container image using the `Containerfile`.

```bash
podman build --tag nix-systemd --file containers/Containerfile .
```

### 2. Provision the Image

Next, run the provisioning script inside the container. This script sets up the user environment. After provisioning, commit the changes to a new image named `provisioned-systemd-home`.

```bash
# Start the container in the background
container_id="$(podman run --detach --rm localhost/nix-systemd:latest)"

# Run the provisioning script as the 'user'
podman exec --user=user -it "$container_id" /provisioner/needs_systemd.bash

# Clean up the provisioning script as 'root'
podman exec --user=root -it "$container_id" rm -rf /provisioner

# Commit the provisioned container to a new image
podman commit "$container_id" provisioned-systemd-home

# Stop the original container
podman kill "$container_id"
```

### 3. Test the Provisioned Image

Now you can start a new container from the `provisioned-systemd-home` image to test the environment.

```bash
# Start the provisioned container in the background
container_id="$(podman run --detach --rm localhost/provisioned-systemd-home)"

# Open an interactive zsh shell as the 'user'
podman exec --user=user --workdir='/home/user' -it "$container_id" /home/user/.nix-profile/bin/zsh

# Inside the container, you can verify the setup
# For example, check the directory structure:
# > la --tree .config
# drwxr-xr-x - user  9 Mar 00:31 .config
# drwxr-xr-x - user  9 Mar 00:31 ├── alacritty

# When you are finished, stop the container
podman kill "$container_id"
```
