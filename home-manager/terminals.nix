{ pkgs, ... }:

{
  xdg = {
    configFile = {
      # Make sure to enable the NixOS module with empty file. See xdg.terminal-exec for detail
      "xdg-terminals.list".text = "";

      "ghostty/config".text = ''
        ${builtins.readFile ../config/ghostty/config.common}

        ${if pkgs.stdenv.isLinux then (builtins.readFile ../config/ghostty/config.linux) else ""}
      '';

      "alacritty/alacritty.toml".source = ../config/alacritty/alacritty-unix.toml;
      "alacritty/unix.toml".source =
        if pkgs.stdenv.isDarwin then ../config/alacritty/macos.toml else ../config/alacritty/linux.toml;
      "alacritty/common.toml".source = ../config/alacritty/common.toml;
      "alacritty/themes" = {
        source = ../config/alacritty/themes;
        recursive = true;
      };
    };
  };
}
