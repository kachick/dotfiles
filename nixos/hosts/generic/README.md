# Usage

Putting the [hardware-configuration.nix](/etc/nixos/hardware-configuration.nix) into this repository is much annoy for each bootstrapping of the device.\
Although it requires impure mode. So I'm putting these files for the purpose.

```bash
cp /etc/nixos/hardware-configuration.nix ./nixos/hosts/generic/

# Comment-in-ont about hardware-configuration.nix in this directory.
git grep 'UPDATEME' ./nixos/hosts/generic

git add .
```

```zsh
nixos-rebuild build --flake .#generic

# Make sure result of above step

# Apply it
sudo nixos-rebuild switch --flake .#generic
```

If you want to use `task apply`, you might require rebooting to apply new hostname.
