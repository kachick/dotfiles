{ ... }:
{
  services.udev = {
    # Settings keyremap in raw layer than X. See GH-784
    #
    # Specify hardware names even if `evdev:input:*` working for mostcase
    extraHwdb = ''
      evdev:name:Topre REALFORCE 87 US:*
        KEYBOARD_KEY_70039=leftctrl # original: capslock
    '';
  };
}
