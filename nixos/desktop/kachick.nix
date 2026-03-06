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
        ../../home-manager/profiles/kachick.nix
        ../../home-manager/targets/linux.nix
        { targets.genericLinux.enable = false; }
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
