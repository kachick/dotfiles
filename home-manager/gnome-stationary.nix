{ ... }:

{
  dconf = {
    settings = {
      "org/gnome/desktop/session" = {
        # Preset time is limited to 1-15 minutes. However, manually entered values appear correctly in the UI.
        idle-delay =
          let
            minutes = 60;
          in
          minutes * 60;
      };
    };
  };
}
