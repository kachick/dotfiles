# What of this config?

Putting the [hardware-configuration.nix](/etc/nixos/hardware-configuration.nix) into this repository is much annoy for each bootstrapping of the device.\
Although it requires impure mode. So I'm putting these files for the purpose.

```bash
cp /etc/nixos/hardware-configuration.nix ./nixos/hosts/generic/

# Comment-in-ont about hardware-configuration.nix around this device. Typically in this repo and .gitignore on root dir of this repository

nix-shell --packages git zsh --command zsh
git init
git add .
```

```zsh
nixos-rebuild build --flake .#this_host_name

# Make sure result of above step

# Apply it
sudo nixos-rebuild switch --flake .#this_host_name
```
