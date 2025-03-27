# A small flake template for bootstrapping

Putting the [hardware-configuration.nix](/etc/nixos/hardware-configuration.nix) into this repository is much annoy for each bootstrapping of the device.\
Although it requires impure mode. So I'm putting these files for the purpose.

```bash
# Avoiding /etc/nixos to reduce much of sudo
mkdir ~/.config
cp this_repo/../this_dir ~/.config/nixos-config
sudo cp /etc/nixos/hardware-configuration.nix ~/.config/nixos-config/

cd ~/.config/nixos-config
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
