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

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMCGvjh2wrEY1+QxRu2hNpHztcZfBueQDPXZMZKBgvY5"
    ];
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
