{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  # ThinkPad E14 Gen 5 (AMD),
  # but replaced unstable RTL8852CE with AX210NGW. See GH-663
  networking.hostName = "moss";

  imports = [
    inputs.home-manager-linux.nixosModules.home-manager
    ../../configuration.nix
    ../../hardware.nix
    ../../desktop
    ../../desktop/kachick.nix

    ./hardware-configuration.nix
    ./fingerprint.nix
  ];

  system.stateVersion = "24.11"; # NOTE: DON'T update this string even if new versions were enabled. See comments in generic/default.nix for details.

  # Apply better fonts for non X consoles
  # https://github.com/NixOS/nixpkgs/issues/219239
  boot.initrd.kernelModules = [ "amdgpu" ];

  boot.loader.systemd-boot = {
    enable = true;
    # https://discourse.nixos.org/t/no-space-left-on-boot/24019/20
    configurationLimit = 10;
  };

  services.xserver.videoDrivers = [ "amdgpu" ];

  services.fstrim.enable = true;

  # You can check the status with `tlp-stat` which installed by enabling this module.
  services.tlp = {
    enable = true;

    settings = {
      # Save long term battery health
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  services.udev.extraHwdb = lib.mkAfter ''
    evdev:name:AT Translated Set 2 keyboard:*
      KEYBOARD_KEY_3a=leftctrl # original: capslock
  '';

  environment.systemPackages = with pkgs; [
    # Available since https://github.com/NixOS/nixpkgs/pull/406363
    (unstable.yaneuraou.override {
      targetLabel = "ZEN3"; # For AMD Ryzen 5 7530U
    })
  ];
}
