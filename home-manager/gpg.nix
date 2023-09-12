{ config, lib, pkgs, ... }:

{
  # https://github.com/nix-community/home-manager/blob/master/modules/services/gpg-agent.nix
  services.gpg-agent.enable = true;

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/gpg.nix
  programs.gpg = (lib.mkMerge [
    {
      enable = true;

      # How to backup the private key?
      # `gpg --export-secret-keys --armor > gpg-private.keys.bak`

      # Preferring XDG_DATA_HOME rather than XDG_CONFIG_HOME from following examples
      #   - https://wiki.archlinux.org/title/XDG_Base_Directory
      #   - https://github.com/nix-community/home-manager/blob/5171f5ef654425e09d9c2100f856d887da595437/modules/programs/gpg.nix#L192
      homedir = "${config.xdg.dataHome}/gnupg";

      # Ed448 in GitHub is not yet supported - https://github.com/orgs/community/discussions/45937
      settings = {
        # https://unix.stackexchange.com/questions/339077/set-default-key-in-gpg-for-signing
        default-key = "EF6E574D040AE2A5";

        personal-digest-preferences = "SHA512";
      };
    }

    (
      # https://github.com/NixOS/nixpkgs/issues/240819#issuecomment-1616760598
      # https://github.com/midchildan/dotfiles/blob/fae87a3ef327c23031d8081333678f9472e4c0ed/nix/home/modules/gnupg/default.nix#L38
      lib.mkIf pkgs.stdenv.isDarwin {
        xdg.dataFile."gnupg/gpg-agent.conf".text = ''
          grab
          pinentry-program ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
        '';
      }
    )
  ]);
}
