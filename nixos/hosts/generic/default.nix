{ lib, ... }:

{
  networking.hostName = lib.mkDefault "nixos";

  imports = [
    ../../configuration.nix
    ../../hardware.nix
    ../../desktop
    ../../desktop/genericUsers.nix

    # ./hardware-configuration.nix # Comment-in only in your new device
  ];

  boot.loader.systemd-boot = {
    enable = true;
    # https://discourse.nixos.org/t/no-space-left-on-boot/24019/20
    configurationLimit = 10;
  };

  # Pseudo values to pass flake check validations
  # You should override in your hardware-configuration.nix

  fileSystems."/" = lib.mkDefault {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
