{ ... }:

{
  networking.hostName = "nixos";

  imports = [
    ../../configuration.nix
    ../../hardware.nix
    ../../desktop
    ../../desktop/genericUsers.nix

    # Don't save the hardware-configuration.nix in this repository for abstracted use-case in several devices even after GH-712.
    # So you should activate impure mode for this host
    /etc/nixos/hardware-configuration.nix
  ];

  boot.loader.systemd-boot = {
    enable = true;
    # https://discourse.nixos.org/t/no-space-left-on-boot/24019/20
    configurationLimit = 10;
  };
}
