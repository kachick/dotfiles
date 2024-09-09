{
  # Modmap for single key rebinds
  services.xremap = {
    enabled = true;
    # https://github.com/xremap/xremap-gnome
    # https://github.com/xremap/nix-flake/blob/3717cb0539f4967010ba540baa439a4cf6ea8576/lib/default.nix#L64-L65
    withGnome = true;

    config = {
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

      # Disabled while using Alt-Space for pop-shell launcher
      # Keymap for key combo rebinds
      # keymap = [
      #   {
      #     name = "Gnome lancher";
      #     remap = {
      #       "Alt-Space" = "LEFTMETA";
      #     };
      #   }
      # ];
    };
  };
}
