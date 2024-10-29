{
  # Modmap for single key rebinds
  services.xremap = {
    enable = true;

    # If xremap does not start or down with some reasons, try `systemctl --user start xremap`
    #
    # https://github.com/xremap/xremap-gnome
    # https://github.com/xremap/nix-flake/blob/3717cb0539f4967010ba540baa439a4cf6ea8576/lib/default.nix#L64-L65
    withGnome = true;

    # Enable when you investigate GH-773
    debug = false;

    # `"system"` mode does not support Gnome
    # You can check the log with `journalctl --user --unit xremap --reverse`
    serviceMode = "user";
    userName = "kachick";
    watch = true;

    config = {
      modmap = [
        {
          name = "Global";
          remap = {
            # "CapsLock" = "Ctrl_L"; # Avoid using xremap to kill capslock for stability. See GH-784
            "Alt_L" = {
              "held" = "Alt_L";
              "alone" = "Muhenkan";
              "alone_timeout_millis" = 500;
            };
            "Alt_R" = "Henkan";
          };
        }
      ];
    };
  };
}
