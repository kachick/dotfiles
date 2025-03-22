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
  boot.kernelPatches = [
    {
      # https://github.com/torvalds/linux/blob/88d324e69ea9f3ae1c1905ea75d717c08bdb8e15/drivers/net/wireless/realtek/rtw89/Kconfig#L87-L96
      name = "enable-rtw89_8852ce-config";
      patch = null;
      extraConfig = ''
        RTW89_8852CE y
      '';
    }
  ];

  # Apply better fonts for non X consoles
  # https://github.com/NixOS/nixpkgs/issues/219239
  boot.initrd.kernelModules = [ "amdgpu" ];

  boot.loader.systemd-boot = {
    enable = true;
    # https://discourse.nixos.org/t/no-space-left-on-boot/24019/20
    configurationLimit = 10;
  };

  systemd = {
    services.systemd-suspend.environment = {
      # TODO: Remove this customization since using nixos-25.05
      SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "true";
    };
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
