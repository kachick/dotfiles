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
    // (mkWritableConfig.xdg "herdr/config.toml" ../config/herdr/config.toml { });
  };
}
