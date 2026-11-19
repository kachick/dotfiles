{
  pkgs,
  config,
  lib,
  ...
}:

{
  xdg.stateFile."vim/.keep".text =
    "Keep this directory because of home-manager and vim does not create the file if directory is missing";

  # https://github.com/nix-community/home-manager/blob/release-26.05/modules/programs/vim.nix
  # https://wiki.nixos.org/wiki/Vim
  programs.vim = {
    # Enabling this may cause collisions. Do not add in packages list
    enable = true;
    packageConfigurable = lib.mkDefault pkgs.vim;
    # nix-env -f '<nixpkgs>' -qaP -A vimPlugins
    plugins = with pkgs.vimPlugins; [
      fzf-vim
    ];

    settings = {
      background = "dark";
    };
    # Force 16 colors so built-in sorbet uses terminal background and palette colors instead of fixed hex values
    extraConfig = ''
      set t_Co=16
      colorscheme sorbet
      set viminfofile=${config.xdg.stateHome}/vim/viminfo
    '';
  };
}
