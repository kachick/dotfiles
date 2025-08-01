{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  networking.hostName = "algae";

  imports = [
    inputs.home-manager-linux.nixosModules.home-manager
    ../../configuration.nix
    ../../hardware.nix
    ../../desktop
    ../../desktop/kachick.nix

    ./hardware-configuration.nix
  ];

  system.stateVersion = "24.11"; # NOTE: DON'T update this string even if new versions were enabled. See comments in generic/default.nix for details.

  # Apply better fonts for non X consoles
  # https://github.com/NixOS/nixpkgs/issues/219239
  boot.initrd.kernelModules = [ "amdgpu" ];

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 20;
  };

  services.xserver.videoDrivers = [ "amdgpu" ];

  services.fstrim.enable = true;

  services.fwupd.enable = true;

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

  # Useful to free-up spaces, however ruunning it causes frozen device with high I/O :<
  # However I may need to enable this on algae again, 1TiB disk is too small for Nix Life
  # nix.optimise = {
  #   automatic = true;
  #   # It seems the timezone is handled automatically, so don't manually adjust with +09:00
  #   dates = [ "26:30" ];
  # };

  # Disable sleep only on this device, even if it's a desktop.
  # This device also serves as a jump host for development, used with SSH and Tailscale-SSH.
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';

  environment.systemPackages = with pkgs; [
    # Available since https://github.com/NixOS/nixpkgs/pull/406363
    (unstable.yaneuraou.override {
      targetLabel = "ZEN2"; # For AMD Ryzen 7 4700GE
    })
  ];
}
