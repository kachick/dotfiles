{ lib, pkgs, ... }:
{
  services.udev = {
    enable = true;
    # Settings keyremap in raw layer than X. See GH-784 for background. And see https://github.com/kachick/dotfiles/wiki/Key-Remapper for the guide
    #
    # Specify hardware names even if `evdev:input:*` working for mostcase. I should care both US and JIS layout
    extraHwdb = lib.mkBefore ''
      evdev:name:Topre REALFORCE 87 US:*
        KEYBOARD_KEY_70039=leftctrl # original: capslock

      evdev:name:Lenovo ThinkPad Compact USB Keyboard with TrackPoint:* # Both US and JIS have same name
        KEYBOARD_KEY_70039=leftctrl # original: capslock, Both US and JIS have same keycode for capslock

      evdev:name:Lenovo Wireless KB Keyboard:* # JIS
        KEYBOARD_KEY_70039=leftctrl # original: capslock
    '';
  };

  # http://www.sane-project.org/sane-mfgs.html#Z-EPSON
  # Apple AirScan supported devices: https://support.apple.com/ja-jp/HT201311
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
  };
}
