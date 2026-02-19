# Generic Host Template

This host configuration serves as a reference for using the exported `nixosModules`.
In most cases, you don't need to copy this directory. Instead, you should import `dotfiles.nixosModules.desktop` or `dotfiles.nixosModules.common` in your own flake.

## How to use this as a base for a new machine

1. Create a new host directory (e.g., `nixos/hosts/my-new-machine`).
2. Generate hardware config: `nixos-generate-config --show-hardware-config > hardware-configuration.nix`.
3. Create `default.nix` and import the modules:

```nix
{ outputs, ... }: {
  imports = [
    outputs.nixosModules.desktop
    outputs.nixosModules.hardware # Optional
    ./hardware-configuration.nix
  ];
  system.stateVersion = "25.11";
}
```
