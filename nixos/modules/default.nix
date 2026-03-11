{ inputs }:
{
  common = ../configuration.nix;
  hardware = ../hardware.nix;
  desktop = ./desktop.nix;
  ephemeral = ../desktop/ephemeral.nix;
  home-manager = inputs.home-manager-linux.nixosModules.home-manager;
  cloudflare-warp = ./cloudflare-warp.nix;
}
