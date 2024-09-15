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
  #
  # - Specify hardware names even if `evdev:input:*` working for mostcase. I should care both US and JIS layout
  # - How to get the KEYBOARD_KEY_700??: `showkey --scancodes` in VT
  # - How to get the hardware name:: `udevadm info --attribute-walk /dev/input/event?? | grep -F 'ATTRS{name}'`
  # - How to apply?: After nixos-rebuild switch `sudo systemd-hwdb update && sudo udevadm trigger`
  environment.etc."udev/hwdb.d/99-local.hwdb".text = ''
    evdev:name:Topre REALFORCE 87 US:*
      KEYBOARD_KEY_70039=leftctrl # original: capslock

    evdev:name:Lenovo ThinkPad Compact USB Keyboard with TrackPoint:* # Both US and JIS have same name
      KEYBOARD_KEY_70039=leftctrl # original: capslock, Both US and JIS have same keycode for capslock
  '';
}
