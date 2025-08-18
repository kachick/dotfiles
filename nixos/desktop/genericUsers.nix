{
  lib,
  pkgs,
  ...
}:

let
  mkUser = import ./mkUser.nix { inherit lib; };
in
{
  users.users = {
    user = mkUser { };
  };

  home-manager = {
    # https://discourse.nixos.org/t/home-manager-useuserpackages-useglobalpkgs-settings/34506/4
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.user = {
      imports = [
        ../../home-manager/genericUser.nix
        {
          targets.genericLinux.enable = false;
        }
        ../../home-manager/linux.nix
        ../../home-manager/lima-host.nix
        ../../home-manager/systemd.nix
        ../../home-manager/desktop.nix
        ../../home-manager/firefox.nix
      ];
    };
    extraSpecialArgs = {
      inherit
        pkgs
        ;
    };
  };
}
