{ ... }:
{
  # services.udev = {
  #   enable = true;
  #   # Settings keyremap in raw layer than X. See GH-784

  #   # Specify hardware names even if `evdev:input:*` working for mostcase
  #   extraHwdb = ''
  #     evdev:name:Topre REALFORCE 87 US:*
  #       # original: capslock
  #       KEYBOARD_KEY_70039=leftctrl
  #   '';
  # };

  # Settings keyremap in raw layer than X. See GH-784
  # Don't use `services.udev.extraHwdb`, it does not create the file at least in NixOS 24.05
  # See https://github.com/NixOS/nixpkgs/issues/182966 for detail
  environment.etc."udev/hwdb.d/99-local.hwdb".text = ''
    evdev:name:Topre REALFORCE 87 US:*
      KEYBOARD_KEY_70039=leftctrl # original: capslock
  '';
}
