{ pkgs, lib, ... }:

{
  xdg = {
    configFile = {
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

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/kitty.nix
  programs.kitty = {
    enable = true;
    package = pkgs.emptyDirectory;
    theme = "zenwritten_dark";
    settings = {
      shell = lib.getExe pkgs.zsh;
      cursor_shape = "beam";
      cursor_blink_interval = 0;
      copy_on_select = "clipboard";
      tab_bar_edge = "top";
      # tab_bar_style = "separator";
      # tab_separator = " | ";
      tab_bar_style = "slant";
    };

    # Avoiding a home-manager definition bug for rejecting all float.
    # https://github.com/nix-community/home-manager/issues/4850
    extraConfig = ''
      background_opacity 0.85
    '';
  };
}
