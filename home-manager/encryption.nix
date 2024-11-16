{
  config,
  pkgs,
  ...
}:

# See https://github.com/kachick/dotfiles/wiki/Encryption for the extracted comments

let
  # All gpg-agent timeouts numbers should be specified with the `seconds`
  day = 60 * 60 * 24;
  passage_identity_dir = "${config.xdg.configHome}/passage";
in
{
  # Don't set $SEQUOIA_HOME, it unified config and data, cache to one directory as same as gpg era.
  # Use default $HOME instead, it respects XDG Base Directory Specification

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/services/gpg-agent.nix
  services.gpg-agent = {
    enable = pkgs.stdenv.isLinux;

    # Update [darwin.nix](darwin.nix) if changed this section
    #
    # https://superuser.com/questions/624343/keep-gnupg-credentials-cached-for-entire-user-session
    defaultCacheTtl = day * 7;
    # https://github.com/openbsd/src/blob/862f3f2587ccb85ac6d8602dd1601a861ae5a3e8/usr.bin/ssh/ssh-agent.1#L167-L173
    # ssh-agent sets it as infinite by default. So I can relax here (maybe)
    defaultCacheTtlSsh = day * 30;
    maxCacheTtl = day * 7;

    pinentryPackage = pkgs.pinentry-tty;

    enableSshSupport = false;
  };

  home.sessionVariables = rec {
    GOPASS_GPG_BINARY = "${pkgs.lib.getBin pkgs.sequoia-chameleon-gnupg}/bin/gpg-sq";

    # Do NOT include the identity here
    PASSAGE_DIR = "${config.xdg.dataHome}/passage/store";

    # Create with: `age-keygen | age --passphrase --armor`
    PASSAGE_IDENTITIES_FILE = "${passage_identity_dir}/identities.age";

    # Create with: `age --decrypt "$PASSAGE_IDENTITIES_FILE" | age-keygen -y`
    PASSAGE_RECIPIENTS_FILE = "${PASSAGE_DIR}/.age-recipients";
  };

  home.file."${passage_identity_dir}/.keep".text = "Keep this directory because of passage and age does not create the file if directory is missing";

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/gpg.nix
  programs.gpg = {
    enable = true;
    # package = pkgs.sequoia-chameleon-gnupg; # Also will be respected in gpg-agent: https://github.com/nix-community/home-manager/blob/5171f5ef654425e09d9c2100f856d887da595437/modules/services/gpg-agent.nix#L8C3-L8C9
    # However I prefer original gnupg for now, sequoia-chameleon-gnupg does not support crucial features for GPG toolset (etc. `gpg --edit-key`, `gpgconf`)

    # Preferring XDG_DATA_HOME rather than XDG_CONFIG_HOME from following examples
    #   - https://wiki.archlinux.org/title/XDG_Base_Directory
    #   - https://github.com/nix-community/home-manager/blob/5171f5ef654425e09d9c2100f856d887da595437/modules/programs/gpg.nix#L192
    homedir = "${config.xdg.dataHome}/gnupg";

    # Used for `gpg.conf`. I don't know how to specify `gpgconf` with this.
    # TODO: Set gpg binary as sequoia-chameleon-gnupg. AFAIK I don't actually need it for now, because I'm not using dependent tools. However it is ideal config.
    # - How to read `--list-keys` - https://unix.stackexchange.com/questions/613839/help-understanding-gpg-list-keys-output
    # - Ed448 in GitHub is not yet supported - https://github.com/orgs/community/discussions/45937
    settings = {
      # https://unix.stackexchange.com/questions/339077/set-default-key-in-gpg-for-signing
      # default-key = "<UPDATE_ME_IN_FLAKE>";

      personal-digest-preferences = "SHA512";
    };
  };

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/password-store.nix
  programs.password-store = {
    enable = true;
    package = pkgs.gopass; # Setting package is not a aliasing command, however I would try this for now. https://github.com/gopasspw/gopass/blob/70c56f9102999661b54e28c28fa2d63fa5fc813b/docs/setup.md?plain=1#L292-L298
  };
}
