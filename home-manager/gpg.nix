{ config, pkgs, ... }:

{
  # https://github.com/nix-community/home-manager/blob/master/modules/services/gpg-agent.nix
  services.gpg-agent.enable = if pkgs.stdenv.isDarwin then false else true;

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/gpg.nix
  programs.gpg =
    {
      enable = true;

      # How to backup the private key?
      # `gpg --export-secret-keys --armor > gpg-private.keys.bak`

      # Preferring XDG_DATA_HOME rather than XDG_CONFIG_HOME from following examples
      #   - https://wiki.archlinux.org/title/XDG_Base_Directory
      #   - https://github.com/nix-community/home-manager/blob/5171f5ef654425e09d9c2100f856d887da595437/modules/programs/gpg.nix#L192
      homedir = "${config.xdg.dataHome}/gnupg";

      # - How to read `--list-keys` - https://unix.stackexchange.com/questions/613839/help-understanding-gpg-list-keys-output
      # - Ed448 in GitHub is not yet supported - https://github.com/orgs/community/discussions/45937
      settings = {
        # https://unix.stackexchange.com/questions/339077/set-default-key-in-gpg-for-signing
        default-key = "C386ED38C00461C9";

        personal-digest-preferences = "SHA512";
      };
    };
}
