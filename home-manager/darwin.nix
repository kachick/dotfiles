{ pkgs, lib, ... }:

# FAQ
#
# A. can not found dot files in macOS finder
# Q. https://apple.stackexchange.com/a/250646, consider to use nix-darwin
#      https://github.com/LnL7/nix-darwin/blob/16c07487ac9bc59f58b121d13160c67befa3342e/modules/system/defaults/finder.nix#L8-L14

# https://github.com/nix-community/home-manager/issues/414#issuecomment-427163925
let
  iterm2Repository = pkgs.fetchFromGitHub
    {
      owner = "gnachman";
      repo = "iTerm2";
      rev = "e7c4c4b1ba6b21a19a48be2dad67048099be176e";
      sha256 = "sha256-7F8l2QEnTMJlOCpT2WQ8f7iv8I96fMqDa5MM4oQAvYQ=";
    };
in
lib.mkMerge [
  (lib.mkIf pkgs.stdenv.isDarwin {
    xdg.configFile."iterm2/com.googlecode.iterm2.plist".source = ../home/.config/iterm2/com.googlecode.iterm2.plist;

    # Do not use `programs.zsh.dotDir`, it does not refer xdg module
    xdg.configHome."zsh/.zshrc.darwin".text = ''
      source ${iterm2Repository + "/Resources/shell_integration/iterm2_shell_integration.zsh"}
    '';

    # Just putting the refererenced file to easy import, applying should be done via GUI and saving to plist
    xdg.configFile."iterm2/OneHalfDark.itermcolors".source =
      pkgs.fetchFromGitHub
        {
          owner = "mbadolato";
          repo = "iTerm2-Color-Schemes";
          rev = "3f8a0791ed9a99c10054026c1a8285459117e0f2";
          sha256 = "sha256-ixryDwSNdVtD1H+V72V+hbFiL/JNLU4qpKXWflPQwrQ=";
        }
      + "/schemes/OneHalfDark.itermcolors"
    ;
  })
]
