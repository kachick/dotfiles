# NixOS Configuration

This directory contains NixOS system configurations.
These settings are exported as `nixosModules`, so you can inherit and reuse them from other flakes.

## How to use from other flakes (Inheritance)

Here is an example of `flake.nix` for your private repository.

```nix
{
  inputs.dotfiles.url = "github:kachick/dotfiles";

  outputs = { self, nixpkgs, dotfiles, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      # Pass 'outputs' to specialArgs to use dotfiles' modules
      specialArgs = { inherit inputs; outputs = dotfiles; };
      modules = [
        # Desktop set (Includes Desktop Environment, Fonts, and GUI Apps)
        dotfiles.nixosModules.desktop
        # Shared hardware tweaks (Keyboard remaps, etc.)
        dotfiles.nixosModules.hardware

        # Your machine specific config (hostname, user, filesystems, etc.)
        ./configuration.nix
      ];
    };

    # Example for WSL or Servers (without Desktop Environment)
    nixosConfigurations.my-wsl = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; outputs = dotfiles; };
      modules = [
        # Import basic CLI config without Desktop
        dotfiles.nixosModules.common
        # Add WSL module (you should define inputs.nixos-wsl in your flake)
        inputs.nixos-wsl.nixosModules.default
        { wsl.enable = true; }
      ];
    };
  };
}
```

### Exported Modules

- `dotfiles.nixosModules.desktop`: For Desktop machines. Includes `common` plus GUI environment (GNOME, Fonts, GUI Apps).
- `dotfiles.nixosModules.common`: Basic system settings (CLI tools, Nix settings, GC, SSH, etc.).
- `dotfiles.nixosModules.hardware`: Common hardware tweaks (Keymaps, udev rules).
- `dotfiles.nixosModules.genericUser`: A generic user named `user` with basic settings.

## Development and Testing

To test the configurations in this repository:

```bash
# Check if the evaluation works for a specific host
nix build ".#nixosConfigurations.generic.config.system.build.toplevel" --dry-run
```
