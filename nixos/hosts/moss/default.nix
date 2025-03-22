{ lib, pkgs, ... }:

{
  networking.hostName = "moss";

  imports = [
    ../../configuration.nix
    ../../hardware.nix
    ../../desktop

    ./hardware-configuration.nix
    ./fingerprint.nix
  ];

  # Use 6.13 or higher to apply 2 commits for using RTL8852CE
  #   - https://github.com/torvalds/linux/commit/0e5210217768625b43f099bcaafe627b098655d5
  #   - https://github.com/torvalds/linux/commit/1f3de77752a7bf0d1beb44603f048eb46948b9fe
  # TODO: Remove this customization since using nixos-25.05
  boot.kernelPackages = pkgs.linuxPackages_6_13;

  # Apply better fonts for non X consoles
  # https://github.com/NixOS/nixpkgs/issues/219239
  boot.initrd.kernelModules = [ "amdgpu" ];

  boot.loader.systemd-boot = {
    enable = true;
    # https://discourse.nixos.org/t/no-space-left-on-boot/24019/20
    configurationLimit = 10;
  };

  services.xserver.videoDrivers = [ "amdgpu" ];

  networking.networkmanager = {
    unmanaged = [
      "except:interface-name:wlp3s0"
    ];
  };

  services.udev.extraHwdb = lib.mkAfter ''
    evdev:name:AT Translated Set 2 keyboard:*
      KEYBOARD_KEY_3a=leftctrl # original: capslock
  '';
}
