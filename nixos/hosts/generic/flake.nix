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
    # 1. Point to this repository.
    #
    # TIPS: While you can point to a branch (e.g., github:kachick/dotfiles/main),
    #       Nix sometimes pulls older revisions from its internal cache even after
    #       recreating flake.lock. To avoid such troubleshooting, using a specific
    #       GIT_SHA is the most reliable way during development or for stability.
    #
    # dotfiles.url = "github:kachick/dotfiles/GIT_SHA_HERE";
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
          # Import modules from the dotfiles input
          # Note: These modules automatically include necessary dependencies (like Home Manager NixOS module)
          dotfiles.nixosModules.desktop
          dotfiles.nixosModules.genericUser

          # Import your own hardware configuration
          # Note: nixos-generate-config --show-hardware-config > hardware-configuration.nix
          ./hardware-configuration.nix

          # Define machine specific settings
          (
            { ... }:
            {
              networking.hostName = "sample";
              system.stateVersion = "25.11";

              # Bootloader settings are not included in common modules to support WSL/Servers.
              # You should enable one of them here.
              boot.loader.systemd-boot.enable = true;
              boot.loader.efi.canTouchEfiVariables = true;
            }
          )
        ];
      };
    };
}
