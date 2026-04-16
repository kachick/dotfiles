{
  lib,
  pkgs,
  outputs,
  ...
}:

{
  networking.hostName = "algae";

  imports = [
    outputs.nixosModules.desktop
    outputs.nixosModules.desktop-unfree
    outputs.nixosModules.hardware
    outputs.nixosModules.cloudflare-warp
    ../../desktop/kachick.nix

    ./hardware-configuration.nix
  ];

  system.stateVersion = "24.11"; # NOTE: DON'T update this string even if new versions were enabled. See comments in generic/default.nix for details.

  # Apply better fonts for non X consoles
  # https://github.com/NixOS/nixpkgs/issues/219239
  boot.initrd.kernelModules = [ "amdgpu" ];

  # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/system/boot/luksroot.nix
  boot.initrd.luks.devices = {
    "luks-9b94a10b-7ca3-4e4f-b52d-b1cf5104b519" = {
      # fstrim is enabled weekly by default:
      # https://github.com/NixOS/nixpkgs/blob/35b4600dfe916d64506ad6dfad275faeca833a6f/nixos/modules/services/misc/fstrim.nix#L16-L22
      # Check "Size/Capacity" and "Utilization" via: sudo smartctl -a /dev/nvme0n1
      # To run fstrim immediately: sudo fstrim -av
      allowDiscards = true; # See GH-1555 for the background

      bypassWorkqueues = true;
    };

    "archive" = {
      allowDiscards = true;
      bypassWorkqueues = true;
    };
  };

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

  # Useful to free up space, however running it causes the device to freeze with high I/O :<
  # However I may need to enable this on algae again, 1 TiB disk is too small for Nix Life
  # nix.optimise = {
  #   automatic = true;
  #   # It seems the timezone is handled automatically, so don't manually adjust with +09:00
  #   dates = [ "26:30" ];
  # };

  environment.systemPackages = with pkgs; [
    # See also https://yaneuraou.yaneu.com/2020/08/02/yaneuraou-ryzen-threadripper-3990x-optimization/
    # Although the CPU is ZEN2, we use AVX2 to leverage the GHA cache and avoid long local builds.
    # Standard GHA runners (ubuntu-24.04) support AVX2, allowing us to run installCheckPhase in CI.
    local.yaneuraou-avx2 # For AMD Ryzen 7 4700GE

    local.hcpu_shogi
  ];
}
