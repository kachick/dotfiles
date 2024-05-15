{ lib, ... }:

{
  imports = [ ./common.nix ];

  home.username = lib.mkDefault "kachick";

  programs.git = {
    userEmail = "kachick1@gmail.com";
    userName = "Kenichi Kamiya";

    extraConfig = {
      user = {
        # - Visibility
        #   - https://stackoverflow.com/questions/48065535/should-i-keep-gitconfigs-signingkey-private
        #   - ANYONE can access the registered public key at https://github.com/kachick.gpg
        # - Append `!` suffix for subkeys
        signingkey = "9BE4016A38165CCB!";
      };

      ghq.user = "kachick";
    };
  };

  programs.gpg = {
    # - How to read `--list-keys` - https://unix.stackexchange.com/questions/613839/help-understanding-gpg-list-keys-output
    # - Ed448 in GitHub is not yet supported - https://github.com/orgs/community/discussions/45937
    settings = {
      # https://unix.stackexchange.com/questions/339077/set-default-key-in-gpg-for-signing
      default-key = "9BE4016A38165CCB";
    };
  };

  # - stack manager can not found in https://github.com/nix-community/home-manager/tree/8d243f7da13d6ee32f722a3f1afeced150b6d4da/modules/programs
  xdg.configFile."stack" = {
    source = ../config/stack;
    recursive = true;
  };
}
