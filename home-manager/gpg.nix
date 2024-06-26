{ config, pkgs, ... }:

# ## FAQ - GPG
#
# - How to list keys?
#   - 1. `gpg --list-secret-keys --keyid-format=long` # The `sec` first section displays same text as `pub` by `gpg --list-keys --keyid-format=long`
# - How to add subkey?
#   - 1. `gpg --edit-key PUBKEY`
#   - 2. `addkey`
#   - 3. `save`
# - How to revoke subkey?
#   - 1. `gpg --edit-key PUBKEY`
#   - 2. `key n` n is the index of subkey
#   - 3. `revkey`
#   - 4. `save`
#   - 5. Replace uploaded pubkey with new one, see https://github.com/kachick/dotfiles/pull/311#issuecomment-1715812324 for detail
# - How to get pubkey to upload?
#   - `gpg --armor --export PUBKEY | clip.exe`
# - How to backup private key?
#   - `gpg --export-secret-keys --armor > gpg-private.keys.bak`
{
  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/services/gpg-agent.nix
  services.gpg-agent = {
    enable = pkgs.stdenv.isLinux;

    # Update [darwin.nix](darwin.nix) if changed this section
    #
    # https://superuser.com/questions/624343/keep-gnupg-credentials-cached-for-entire-user-session
    defaultCacheTtl = 60480000; # 700 days
    maxCacheTtl = 60480000; # 700 days

    pinentryPackage = pkgs.pinentry-tty;
  };

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/gpg.nix

  programs.gpg = {
    enable = true;

    # Preferring XDG_DATA_HOME rather than XDG_CONFIG_HOME from following examples
    #   - https://wiki.archlinux.org/title/XDG_Base_Directory
    #   - https://github.com/nix-community/home-manager/blob/5171f5ef654425e09d9c2100f856d887da595437/modules/programs/gpg.nix#L192
    homedir = "${config.xdg.dataHome}/gnupg";

    # - How to read `--list-keys` - https://unix.stackexchange.com/questions/613839/help-understanding-gpg-list-keys-output
    # - Ed448 in GitHub is not yet supported - https://github.com/orgs/community/discussions/45937
    settings = {
      # https://unix.stackexchange.com/questions/339077/set-default-key-in-gpg-for-signing
      # default-key = "<UPDATE_ME_IN_FLAKE>";

      personal-digest-preferences = "SHA512";
    };
  };
}
