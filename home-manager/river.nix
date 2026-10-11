{ pkgs, ... }:

{
  wayland.windowManager.river = {
    enable = true;
    # Why river-classic:
    # river 0.4+ in nixpkgs is a non-monolithic compositor without built-in wm or rivertile.
    # river-classic (0.3.x) provides the dynamic tiling compositor with riverctl and rivertile.
    package = pkgs.river-classic;
    extraConfig = ''
      # Terminal: using ghostty as preferred terminal
      riverctl map normal Super Return spawn ${pkgs.ghostty}/bin/ghostty

      # Launcher: fuzzel as a lightweight Wayland native dmenu/rofi alternative
      riverctl map normal Super Space spawn ${pkgs.fuzzel}/bin/fuzzel

      # Window management
      riverctl map normal Super Q close
      riverctl map normal Super+Shift E exit
      riverctl map normal Super J focus-view next
      riverctl map normal Super K focus-view previous
      riverctl map normal Super+Shift J swap next
      riverctl map normal Super+Shift K swap previous

      # Layout orientation
      riverctl map normal Super Up send-layout-cmd rivertile "main-location top"
      riverctl map normal Super Right send-layout-cmd rivertile "main-location right"
      riverctl map normal Super Down send-layout-cmd rivertile "main-location bottom"
      riverctl map normal Super Left send-layout-cmd rivertile "main-location left"

      # Mouse bindings
      riverctl map-pointer normal Super BTN_LEFT move-view
      riverctl map-pointer normal Super BTN_RIGHT resize-view
      riverctl map-pointer normal Super BTN_MIDDLE toggle-float

      # Colors and borders
      riverctl background-color 0x1e1e2e
      riverctl border-color-focused 0x89b4fa
      riverctl border-color-unfocused 0x45475a
      riverctl border-width 2

      # Default layout generator
      riverctl default-layout rivertile
      ${pkgs.river-classic}/bin/rivertile -view-padding 4 -outer-padding 4 &

      # Launch ghostty on startup
      ${pkgs.ghostty}/bin/ghostty &
    '';
  };

  home.packages = with pkgs; [
    fuzzel
    grim
  ];
}
