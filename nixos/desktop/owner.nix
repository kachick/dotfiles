{
  lib,
  ...
}:

let
  mkUser = import ./mkUser.nix { inherit lib; };
  username = "owner";
in
{
  users.users.${username} = mkUser {
    extraGroups = [
      "wheel" # Required by sudo and Nix trusted-users
      "libvirtd" # GUI VM management
      "wireshark"
    ];

    openssh.authorizedKeys.keys = import ../../config/ssh/keys.nix;
  };

  home-manager.users.${username} = {
    imports = [
      ../../home-manager/kachick.nix
      ../../home-manager/nixos-desktop-set.nix
    ];
  };

  # Linux tailscaled only accepts one operator username, not a group.
  # https://github.com/tailscale/tailscale/issues/17817
  services.tailscale.extraSetFlags = [ "--operator=${username}" ];
}
