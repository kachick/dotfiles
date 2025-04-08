{
  pkgs,
  ...
}:

let
  mkUser = import ./mkUser.nix;
in
{
  users.users.kachick = mkUser {
    description = "foolish";
  };

  home-manager = {
    # https://discourse.nixos.org/t/home-manager-useuserpackages-useglobalpkgs-settings/34506/4
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.kachick = {
      imports = [
        ../../home-manager/kachick.nix
        ../../home-manager/linux.nix
        { targets.genericLinux.enable = false; }
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
