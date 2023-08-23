{ pkgs, lib, ... }:

# https://github.com/nix-community/home-manager/issues/414#issuecomment-427163925
lib.mkMerge [
  (lib.mkIf pkgs.stdenv.isDarwin {
    xdg.configFile."iterm2/com.googlecode.iterm2.plist".source = ../home/.config/iterm2/com.googlecode.iterm2.plist;

    # Do not use `programs.zsh.dotDir`, it does not refer xdg module

    xdg.configFile."zsh/.zshenv.darwin".text = ''
      # See https://github.com/kachick/dotfiles/issues/159 and https://github.com/NixOS/nix/issues/3616
      # nix loaded programs may be used in zshrc and non interactive mode, so this workaround should be included in zshenv
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi
    '';

    xdg.configFile."zsh/.zshrc.darwin".text = ''
      source ${pkgs.iterm2 + "/Applications/iTerm2.app/Contents/Resources/iterm2_shell_integration.zsh"}
    '';

    # Just putting the refererenced file to easy import, applying should be done via GUI and saving to plist
    # You can find color schemes at schemes/ directory
    xdg.configFile."iterm2/iTerm2-Color-Schemes".source =
      pkgs.fetchFromGitHub
        {
          owner = "mbadolato";
          repo = "iTerm2-Color-Schemes";
          rev = "64184d90e6377dd5dc3902057aff867ad8750bed";
          sha256 = "sha256-FJITWlw3iVCdrurlS0Vv/s3Sc8ZKth7qmyIdcpPrDn4";
        }
    ;
  })
]
