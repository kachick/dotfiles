{ config, ... }:

{
  # https://github.com/nix-community/home-manager/blob/master/modules/services/gpg-agent.nix
  services.gpg-agent.enable = true;

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/gpg.nix
  programs.gpg = {
    enable = true;

    # Preferring XDG_DATA_HOME rather than XDG_CONFIG_HOME from following examples
    #   - https://wiki.archlinux.org/title/XDG_Base_Directory
    #   - https://github.com/nix-community/home-manager/blob/5171f5ef654425e09d9c2100f856d887da595437/modules/programs/gpg.nix#L192
    homedir = "${config.xdg.dataHome}/gnupg";

    # Ed448 in GitHub is not yet supported - https://github.com/orgs/community/discussions/45937
    settings = {
      personal-digest-preferences = "SHA512";
    };
  };
}
