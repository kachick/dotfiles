{ inputs }:
{
  common = ../configuration.nix;
  hardware = ../hardware.nix;
  desktop = ./desktop.nix;
  genericUser =
    { outputs, ... }:
    {
      imports = [
        outputs.nixosModules.home-manager
        ../desktop/genericUsers.nix
      ];
    };
  home-manager = inputs.home-manager-linux.nixosModules.home-manager;
}
