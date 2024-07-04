{
  # Modmap for single key rebinds
  services.xremap.config = {
    modmap = [
      {
        name = "Global";
        remap = {
          "CapsLock" = "Ctrl_L";
          "Alt_L" = {
            "held" = "Alt_L";
            "alone" = "Muhenkan";
            "alone_timeout_millis" = 500;
          };
          "Alt_R" = "Henkan";
        };
      }
    ];

    # Keymap for key combo rebinds
    keymap = [
      {
        name = "Gnome lancher";
        remap = {
          "Alt-Space" = "LEFTMETA";
        };
      }
    ];
  };
}
