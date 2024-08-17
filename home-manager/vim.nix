{ pkgs, homemade-pkgs, ... }:

{
  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/vim.nix
  # https://nixos.wiki/wiki/Vim
  programs.vim = {
    # Enabling this may cause colisions. Do not add in packages list
    enable = true;
    # nix-env -f '<nixpkgs>' -qaP -A vimPlugins
    plugins =
      (with pkgs.vimPlugins; [
        iceberg-vim
        fzf-vim
      ])
      ++ [ homemade-pkgs.kdl-vim ];

    settings = {
      background = "dark";
    };
    extraConfig = ''
      colorscheme iceberg
      set termguicolors
    '';
  };
}
