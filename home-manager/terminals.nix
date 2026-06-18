{
  mkWritableConfig,
  ...
}:

{
  xdg = {
    configFile = {
      # Make sure to enable the NixOS module with empty file. See xdg.terminal-exec for details
      "xdg-terminals.list".text = "";

      "alacritty/alacritty.toml".source = ../config/alacritty/alacritty-unix.toml;
      "alacritty/unix.toml".source = ../config/alacritty/linux.toml;
      "alacritty/common.toml".source = ../config/alacritty/common.toml;
      "alacritty/themes" = {
        source = ../config/alacritty/themes;
        recursive = true;
      };
    }
    // (mkWritableConfig.xdg "ghostty/config" ../config/ghostty/config { });
  };
}
