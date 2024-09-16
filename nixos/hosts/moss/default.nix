{ ... }:

{
  networking.hostName = "moss";

  imports = [
    ../../configuration.nix
    ../../hardware.nix
    ../../desktop

    ./hardware-configuration.nix
    ./fingerprint.nix
  ];

  # Apply better fonts for non X consoles
  # https://github.com/NixOS/nixpkgs/issues/219239
  boot.initrd.kernelModules = [ "amdgpu" ];

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 20;
  };

  services.xserver.videoDrivers = [ "amdgpu" ];

  # Settings keyremap in raw layer than X. See GH-784
  # Don't use `services.udev.extraHwdb`, it does not create the file at least in NixOS 24.05
  # See https://github.com/NixOS/nixpkgs/issues/182966 for detail
  environment.etc."udev/hwdb.d/99-local.hwdb".text = ''
    evdev:name:AT Translated Set 2 keyboard:*
      KEYBOARD_KEY_3a=leftctrl # original: capslock
  '';
}
