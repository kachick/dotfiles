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
        ../../home-manager/ephemeral.nix
        ../../home-manager/nixos-desktop-set.nix
      ];
    };
    extraSpecialArgs = {
      inherit
        pkgs
        ;
    };
  };
}
