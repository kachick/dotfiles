{ ... }:

# https://github.com/nix-community/home-manager/blob/master/modules/programs/lazygit.nix
{
  xdg.configFile."git/config".source = ../home/.config/git/config;

  programs.lazygit = {
    enable = true;

    # https://dev.classmethod.jp/articles/eetann-lazygit-config-new-option/
    settings = {
      gui = {
        language = "ja";
        showIcons = true;
        theme = {
          lightTheme = true;
        };
      };
    };
  };
}
