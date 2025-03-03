{ ... }:

{
  networking.hostName = "reboulia";

  imports = [
    ../../configuration.nix
    ../../hardware.nix
    ../../desktop

    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot = {
    enable = true;
    # https://discourse.nixos.org/t/no-space-left-on-boot/24019/20
    configurationLimit = 10;
  };

  # services.udev.extraHwdb = lib.mkAfter ''
  #   evdev:name:AT Translated Set 2 keyboard:*
  #     KEYBOARD_KEY_3a=leftctrl # original: capslock
  # '';
}
