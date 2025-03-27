# A small flake template for bootstrapping

Putting the [hardware-configuration.nix](/etc/nixos/hardware-configuration.nix) into this repository is much annoy for each bootstrapping of the device.\
Although it requires impure mode. So I'm putting these files for the purpose.

```bash
cd this_repo
sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.bakup
sudo cp ./nixos/hosts/generic/flake.nix /etc/nixos/
sudo cp ./nixos/hosts/generic/configuration.nix /etc/nixos/
cd /etc/nixos/
nix-shell --packages git zsh --command zsh
```

```zsh
alias sudoc=sudo --preserve-env=PATH env
sudoc git init
sudoc git config --global --add safe.directory /etc/nixos
sudo nixos-rebuild build --flake "$PWD#this_host_name"

# Make sure result of above steps and apply it
sudo nixos-rebuild switch --flake "$PWD#this_host_name"
```
