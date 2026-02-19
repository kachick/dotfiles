# This is a sample flake.nix to demonstrate how to inherit configurations from this repository.
# You can copy this to your own project and run:
#   nix build ".#nixosConfigurations.sample.config.system.build.toplevel" --dry-run

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    # Point to this repository
    dotfiles.url = "github:kachick/dotfiles";
  };

  outputs =
    { nixpkgs, dotfiles, ... }@inputs:
    {

      nixosConfigurations.sample = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        # Important: Pass 'dotfiles' as 'outputs' to specialArgs
        specialArgs = {
          inherit inputs;
          outputs = dotfiles;
        };
        modules = [
          # 1. Import the base desktop settings from dotfiles
          dotfiles.nixosModules.desktop

          # 2. Import the generic user definition
          dotfiles.nixosModules.genericUser

          # 3. Define your hardware (Use nixos-generate-config to get this)
          # ./hardware-configuration.nix

          # 4. Define machine specific settings
          (
            { ... }:
            {
              networking.hostName = "sample";
              system.stateVersion = "25.11";

              # Pseudo file system for dry-run
              fileSystems."/" = {
                device = "/dev/sda1";
                fsType = "ext4";
              };

              # Use systemd-boot for the sample
              boot.loader.systemd-boot.enable = true;
              boot.loader.efi.canTouchEfiVariables = true;
            }
          )
        ];

      };
    };
}
