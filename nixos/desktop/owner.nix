{
  lib,
  ...
}:

let
  mkUser = import ./mkUser.nix { inherit lib; };
in
{
  users.users.owner = mkUser {
    description = "foolish";
    additionalGroups = [
      "wheel"
      "wireshark"
    ];

    openssh.authorizedKeys.keys = import ../../config/ssh/keys.nix;
  };

  home-manager.users.owner = {
    imports = [
      ../../home-manager/kachick.nix
      ../../home-manager/nixos-desktop-set.nix
    ];
  };
}
