# NixOS Configuration

This directory contains NixOS system configurations.
These settings are exported as `nixosModules`, so you can inherit and reuse them from other flakes.

## How to use from other flakes (Inheritance)

Here is a minimal example of `flake.nix` for your repository.
You can find a more detailed template in [nixos/hosts/sample](./hosts/sample/flake.nix).

```nix
{
  inputs = {
    dotfiles.url = "github:kachick/dotfiles";
    nixpkgs.follows = "dotfiles/nixpkgs";
  };

  outputs = { self, nixpkgs, dotfiles, ... }@inputs: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      # Pass 'dotfiles' as 'outputs' to specialArgs.
      # This is required for internal module cross-references.
      specialArgs = { inherit inputs; outputs = dotfiles; };
      modules = [
        # Desktop set (Includes common CLI, Desktop Environment, Fonts, and GUI Apps)
        dotfiles.nixosModules.desktop

        # Your machine specific config (hostname, user, filesystems, etc.)
        ./configuration.nix
      ];
    };
  };
}
```

## Development and Testing

To verify the sample configuration against the current repository state:

```bash
task test-sample-nixos
```
