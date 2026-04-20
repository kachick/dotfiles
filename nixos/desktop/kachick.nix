{
  lib,
  pkgs,
  ...
}:

let
  mkUser = import ./mkUser.nix { inherit lib; };
in
{
  users.users.kachick = mkUser {
    description = "foolish";
    additionalGroups = [
      "wheel"
      "wireshark"
    ];

    openssh.authorizedKeys.keys = import ../../config/ssh/keys.nix;
  };

  home-manager = {
    # https://discourse.nixos.org/t/home-manager-useuserpackages-useglobalpkgs-settings/34506/4
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.kachick = {
      imports = [
        ../../home-manager/kachick.nix
        ../../home-manager/nixos-desktop-set.nix
        ../../home-manager/lima-host.nix
      ];
    };
    extraSpecialArgs = {
      inherit
        pkgs
        ;
    };
  };
}
