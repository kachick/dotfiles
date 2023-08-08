{ pkgs, lib, ... }:

# https://github.com/nix-community/home-manager/issues/414#issuecomment-427163925
lib.mkMerge [
  (lib.mkIf pkgs.stdenv.isDarwin {
    xdg.configFile."iterm2/com.googlecode.iterm2.plist".source = ../home/.config/iterm2/com.googlecode.iterm2.plist;

    # Do not use `programs.zsh.dotDir`, it does not refer xdg module
    xdg.configFile."zsh/.zshrc.darwin".text = ''
      # See https://github.com/kachick/dotfiles/issues/159 and https://github.com/NixOS/nix/issues/3616
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi

      source ${pkgs.iterm2 + "/Applications/iTerm2.app/Contents/Resources/iterm2_shell_integration.zsh"}
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
