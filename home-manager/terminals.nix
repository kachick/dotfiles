{
  pkgs,
  mkWritableConfig,
  ...
}:

{
  xdg = {
    configFile =
      let
        ghosttyConfig = pkgs.writeText "ghostty-config" ''
          ${builtins.readFile ../config/ghostty/config.common}

          ${if pkgs.stdenv.isLinux then (builtins.readFile ../config/ghostty/config.linux) else ""}
        '';
      in
      {
        # Make sure to enable the NixOS module with empty file. See xdg.terminal-exec for detail
        "xdg-terminals.list".text = "";

        "alacritty/alacritty.toml".source = ../config/alacritty/alacritty-unix.toml;
        "alacritty/unix.toml".source =
          if pkgs.stdenv.isDarwin then ../config/alacritty/macos.toml else ../config/alacritty/linux.toml;
        "alacritty/common.toml".source = ../config/alacritty/common.toml;
        "alacritty/themes" = {
          source = ../config/alacritty/themes;
          recursive = true;
        };
      }
      // (mkWritableConfig.xdg "ghostty/config" ghosttyConfig { });
  };
}
