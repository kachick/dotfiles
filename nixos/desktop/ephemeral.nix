{
  lib,
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

  home-manager.users.user = {
    imports = [
      ../../home-manager/ephemeral.nix
      ../../home-manager/nixos-desktop-set.nix
    ];
  };
}
