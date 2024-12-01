{ pkgs, lib, ... }:

{
  networking.hostName = "algae";

  imports = [
    ../../configuration.nix
    ../../hardware.nix
    ../../desktop

    ./hardware-configuration.nix
  ];

  # Workaround to fix GH-959
  # TODO: Remove after NixOS stable using kernel 6.12 or later. Basically it should be 25.05
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Apply better fonts for non X consoles
  # https://github.com/NixOS/nixpkgs/issues/219239
  boot.initrd.kernelModules = [ "amdgpu" ];

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 20;
  };

  services.xserver.videoDrivers = [ "amdgpu" ];

  # Required to reboot if you want to apply changes
  # Prevent GH-894
  # https://askubuntu.com/a/1446653
  services.udev.extraRules = lib.mkAfter ''
    # Enable USB port 3 wakeup
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="2109", ATTRS{idProduct}=="2817", ATTRS{busnum}=="3", ATTR{power/wakeup}="enabled"
    # Disable USB Switcher wakeup
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="5411", ATTR{power/wakeup}="disabled"
    # Enable trackball - "Kensington SlimBlade Pro Trackball(Wired)" wakeup
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="047d", ATTRS{idProduct}=="80d7", ATTR{power/wakeup}="enabled"
    # Enable keyboard - "REALFORCE 87 US" wakeup
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="0853", ATTRS{idProduct}=="0146", ATTR{power/wakeup}="enabled"
    # Enable keyboard - "ThinkPad Compact USB Keyboard with TrackPoint" wakeup
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="17ef", ATTRS{idProduct}=="6047", ATTR{power/wakeup}="enabled"
  '';
}
