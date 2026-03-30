{ inputs }:
{
  common = ../configuration.nix;
  hardware = ../hardware.nix;
  desktop = ./desktop.nix;
  desktop-unfree = ./desktop-unfree.nix;
  ephemeral = ../desktop/ephemeral.nix;
  home-manager = inputs.home-manager-linux.nixosModules.home-manager;
}
