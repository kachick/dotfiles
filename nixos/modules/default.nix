{ inputs }:
{
  common = ../configuration.nix;
  hardware = ../hardware.nix;
  desktop-base = ./desktop-base.nix;
  desktop = ./desktop.nix;
  desktop-unfree = ../desktop/unfree.nix;
  game = ../desktop/game.nix;
  game-unfree = ../desktop/game-unfree.nix;
  ephemeral = ../desktop/ephemeral.nix;
  home-manager =
    { pkgs, outputs, ... }:
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
      ];
      # https://discourse.nixos.org/t/home-manager-useuserpackages-useglobalpkgs-settings/34506/4
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        extraSpecialArgs = {
          inherit
            pkgs
            outputs
            ;
        };
      };
    };
  cloudflare-warp = ./cloudflare-warp.nix;
  swap = ./swap.nix;
}
