{
  modulesPath,
  pkgs,
  lib,
  outputs,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")

    outputs.nixosModules.desktop
    ../../desktop/kachick.nix
  ];

  # desktop-free is a generic NixOS configuration that contains only free software.
  networking.hostName = "installer";

  system.stateVersion = "25.11";

  # ISO specific optimizations from NixOS Wiki
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;

  # Resolve conflict between installation-device.nix (sudo) and our common config (sudo-rs)
  security.sudo.enable = lib.mkForce false;
  security.sudo-rs.enable = lib.mkForce true;

  # Enable SSH in the boot process as recommended by Wiki
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  # Force use the same authorized keys as kachick user for root as well
  users.users.root.openssh.authorizedKeys.keys = import ../../../config/ssh/keys.nix;
}
