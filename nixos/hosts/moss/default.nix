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
    inputs.home-manager.nixosModules.home-manager
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

  services.fwupd.enable = true;

  # Don't use this charge_control_*_threshold config for now, while GNOME and UPower integrations are working
  # However GNOME's "Preserve Battery Health" seems incomplete the UI and behavior for me.
  # Keep in mind for below links
  # - https://gitlab.gnome.org/GNOME/gnome-control-center/-/merge_requests/2176
  # - https://gitlab.gnome.org/GNOME/gnome-control-center/-/issues/2553
  # - https://gitlab.gnome.org/GNOME/gnome-control-center/-/issues/3456
  # - https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/7904
  # - https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/5429
  # - https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/5228
  # You can manually check the current value with `ls`, `cat` the /sys/class/power_supply/BAT0/ files or `upower --dump`
  # And you can watch the GNOME changed value with `upower --monitor-detail`.
  # `dconf watch /` cannot support this UPower integrations.
  #
  # # Don't use TLP on this device.
  # systemd.services.battery-charge-threshold = {
  #   description = "Limit battery charging on power-profiles-daemon for longevity";
  #   script = ''
  #     echo 40 | tee /sys/class/power_supply/BAT0/charge_control_start_threshold
  #     echo 80 | tee /sys/class/power_supply/BAT0/charge_control_end_threshold
  #   '';
  #   wantedBy = [ "multi-user.target" ];
  # };

  services.udev.extraHwdb = lib.mkAfter ''
    evdev:name:AT Translated Set 2 keyboard:*
      KEYBOARD_KEY_3a=leftctrl # original: capslock
  '';

  environment.systemPackages = with pkgs; [
    (unstable.yaneuraou.override {
      # Prefer "AVX2" rather than "ZEN3". Because of ZEN3 does not need workaround about PEXT problems
      # See also https://yaneuraou.yaneu.com/2020/08/02/yaneuraou-ryzen-threadripper-3990x-optimization/
      targetLabel = "AVX2"; # For AMD Ryzen 5 7530U
    })
  ];
}
