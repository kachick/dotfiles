{ pkgs, lib, ... }:

# https://github.com/nix-community/home-manager/issues/414#issuecomment-427163925
lib.mkMerge [
  (lib.mkIf pkgs.stdenv.isDarwin {
    # https://github.com/NixOS/nixpkgs/issues/240819#issuecomment-1616760598
    # https://github.com/midchildan/dotfiles/blob/fae87a3ef327c23031d8081333678f9472e4c0ed/nix/home/modules/gnupg/default.nix#L38
    xdg.dataFile."gnupg/gpg-agent.conf".text = ''
      grab
      default-cache-ttl 60480000
      max-cache-ttl 60480000
      pinentry-program ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
    '';
  })
]
