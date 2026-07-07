{
  mkWritableConfig,
  ...
}:

{
  # https://github.com/nix-community/home-manager/blob/release-26.05/modules/programs/zellij.nix
  programs.zellij = {
    enable = true;

    # Don't use settings, nix and KDL is much unfit: https://github.com/NixOS/nixpkgs/issues/198655#issuecomment-1453525659
  };

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

      zellij = {
        source = ../config/zellij;
        recursive = true;
      };

      "zellij/simplified-ui.kdl" = {
        text = builtins.readFile ../config/zellij/config.kdl + ''
          // Use a simplified UI without special fonts (arrow glyphs)
          // This is necessary on Linux VT to avoid Tofu
          // Or you can run zellij with `zellij options --simplified-ui true`
          simplified_ui true
        '';
      };
    }
    // (mkWritableConfig.xdg "ghostty/config" ../config/ghostty/config { })
    // (mkWritableConfig.xdg "herdr/config.toml" ../config/herdr/config.toml { });
  };
}
