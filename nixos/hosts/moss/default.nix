{
  lib,
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

  # Apply better fonts for non X consoles
  # https://github.com/NixOS/nixpkgs/issues/219239
  boot.initrd.kernelModules = [ "amdgpu" ];

  boot.loader.systemd-boot = {
    enable = true;
    # https://discourse.nixos.org/t/no-space-left-on-boot/24019/20
    configurationLimit = 10;
  };

  services.xserver.videoDrivers = [ "amdgpu" ];

  services.udev.extraHwdb = lib.mkAfter ''
    evdev:name:AT Translated Set 2 keyboard:*
      KEYBOARD_KEY_3a=leftctrl # original: capslock
  '';
}
