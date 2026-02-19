# This is a sample flake.nix to demonstrate how to inherit configurations from this repository.
#
# Steps to use:
#  1. Copy this file to your project root.
#  2. Generate your hardware config:
#     nixos-generate-config --show-hardware-config > hardware-configuration.nix
#  3. Run dry-run to verify:
#     nix build ".#nixosConfigurations.sample.config.system.build.toplevel" --dry-run

{
  inputs = {
    # 1. Point to this repository
    # If you are pointing to a working branch instead of main, use:
    # dotfiles.url = "github:kachick/dotfiles/YOUR_BRANCH_NAME";
    dotfiles.url = "github:kachick/dotfiles";

    # 2. Inherit nixpkgs and home-manager from dotfiles to ensure consistency and cache hits
    nixpkgs.follows = "dotfiles/nixpkgs";
    home-manager.follows = "dotfiles/home-manager-linux";
  };

  outputs =
    { nixpkgs, dotfiles, ... }@inputs:
    {
      nixosConfigurations.sample = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        # Important: Pass 'dotfiles' as 'outputs' to specialArgs for internal module imports
        specialArgs = {
          inherit inputs;
          outputs = dotfiles;
        };
        modules = [
          # 1. Import modules from the dotfiles input
          # Note: These modules automatically include necessary dependencies (like Home Manager NixOS module)
          dotfiles.nixosModules.desktop
          dotfiles.nixosModules.genericUser

          # 2. Import your own hardware configuration
          # Note: nixos-generate-config creates this file for you
          ./hardware-configuration.nix

          # 3. Define machine specific settings
          (
            { ... }:
            {
              networking.hostName = "sample";
              system.stateVersion = "25.11";
            }
          )
        ];
      };
    };
}
