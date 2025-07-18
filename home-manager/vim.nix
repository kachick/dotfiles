{
  pkgs,
  config,
  ...
}:

{
  xdg.stateFile."vim/.keep".text =
    "Keep this directory because of home-manager and vim does not create the file if directory is missing";

  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/programs/vim.nix
  # https://nixos.wiki/wiki/Vim
  programs.vim = {
    # Enabling this may cause colisions. Do not add in packages list
    enable = true;
    # nix-env -f '<nixpkgs>' -qaP -A vimPlugins
    plugins = with pkgs.vimPlugins; [
      iceberg-vim
      fzf-vim
      kdl-vim
    ];

    settings = {
      background = "dark";
    };
    extraConfig = ''
      colorscheme iceberg
      set termguicolors
      set viminfofile=${config.xdg.stateHome}/vim/viminfo
    '';
  };
}
