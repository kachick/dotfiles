{ lib, pkgs, ... }:
{
  # networking.wireless.enable = true; # Enables wireless support via wpa_supplicant. Bascically prefer networkmanager, enable this if unstable

  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/networking/networkmanager.nix
  networking.networkmanager = {
    enable = true;

    # TIPS: If you are debugging, dmesg with ctime/iso will display incorrect timestamp
    # Then `journalctl --dmesg --output=short-iso --since='1 hour ago' --follow` might be useful
  };

  services.udev = {
    enable = true;
    # Settings keyremap in raw layer than X. See GH-784 and GH-963 for background. And see https://github.com/kachick/dotfiles/wiki/Key-Remapper for the guide
    #
    # - Specify hardware names even if `evdev:input:*` working for mostcase. I should care both US and JIS layout
    # - You can get the devicename, scancode and keycode with evtest. So kill keyremappers and run `evtest` with no arguments. Interactively choose the device
    extraHwdb = lib.mkBefore ''
      evdev:name:Topre REALFORCE 87 US:*
        KEYBOARD_KEY_70039=leftctrl # original: capslock

      evdev:name:Lenovo ThinkPad Compact USB Keyboard with TrackPoint:* # Both US and JIS have same name
        KEYBOARD_KEY_70039=leftctrl # original: capslock, Both US and JIS have same keycode for capslock
        KEYBOARD_KEY_70088=henkan # original: KATAKANAHIRAGANA, guessing US does not have this code, fix me with specifying vendor and product id if required

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
