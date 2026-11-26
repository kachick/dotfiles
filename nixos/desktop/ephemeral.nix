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
    visitor = mkUser { };
  };

  home-manager.users.visitor = {
    imports = [
      ../../home-manager/ephemeral.nix
      ../../home-manager/nixos-desktop-set.nix
    ];
  };
}
