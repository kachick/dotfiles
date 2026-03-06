{
  lib,
  pkgs,
  outputs,
  ...
}:

let
  mkUser = import ./mkUser.nix { inherit lib; };
in
{
  imports = [
    outputs.nixosModules.home-manager
  ];

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
        ../../home-manager/profiles/ephemeral.nix
        {
          targets.genericLinux.enable = false;
        }
        ../../home-manager/targets/linux.nix
        ../../home-manager/targets/lima-host.nix
        ../../home-manager/services/systemd.nix
        ../../home-manager/programs/desktop.nix
        ../../home-manager/programs/firefox.nix
      ];
    };
    extraSpecialArgs = {
      inherit
        pkgs
        ;
    };
  };
}
