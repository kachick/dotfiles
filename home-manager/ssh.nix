{
  pkgs,
  config,
  ...
}:

let
  # SSH files cannot use XDG Base Directory.
  # I don't have permission to read https://bugzilla.mindrot.org/show_bug.cgi?id=2050, but several sources tells us, it is the answer
  #   - https://wiki.archlinux.jp/index.php/XDG_Base_Directory
  #   - https://superuser.com/a/1606519/120469
  sshDir = "${config.home.homeDirectory}/.ssh";
  sharedConfig = {
    identityFile = "${sshDir}/id_ed25519";
    identitiesOnly = true;
    user = "git";
  };
in
# - id_*: Do NOT share in different machines, do NOT tell to anyone. They are secrets.
# - id_*.pub: I CAN register them for different services.
{
  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/services/ssh-agent.nix
  services.ssh-agent.enable = pkgs.stdenv.isLinux;

  home.sessionVariables = {
    # 'force' ignores $DISPLAY. 'prefer' is not enough
    SSH_ASKPASS_REQUIRE = "force";
    SSH_ASKPASS = pkgs.lib.getExe (
      pkgs.writeShellApplication {
        name = "ssh-ask-pass";
        text = "gopass show ssh-pass";
        meta.description = "GH-714. Required to be wrapped with one command because of SSH_ASKPASS does not accept arguments.";
        runtimeInputs = with pkgs; [
          gopass
          sequoia-chameleon-gnupg
        ];
        runtimeEnv = {
          GOPASS_GPG_BINARY = "${pkgs.lib.getBin pkgs.sequoia-chameleon-gnupg}/bin/gpg-sq";
        };
      }
    );
  };

  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/programs/ssh.nix
  programs.ssh = {
    enable = true;

    # https://groups.google.com/g/opensshunixdev/c/e5-kTKpxcaI/m/bdVNyL4BBAAJ
    hashKnownHosts = false;

    # It accepts multiple files separated by whitespace. See https://man.openbsd.org/ssh_config#UserKnownHostsFile for detail
    userKnownHostsFile = "${../config/ssh/known_hosts} ${sshDir}/known_hosts.local";

    # unit: seconds
    serverAliveInterval = 60;

    forwardAgent = true;

    controlMaster = "auto";
    controlPersist = "10m";
    # Used %r by default. And it makes `ControlPath too long` especially using upterm.
    # See following resources and GH-1030
    # https://github.com/nix-community/home-manager/blob/20665c6efa83d71020c8730f26706258ba5c6b2a/modules/programs/ssh.nix#L424-L430
    # https://github.com/owenthereal/upterm/issues/283#issuecomment-2508582116
    controlPath = "~/.ssh/master-%C@%n:%p";

    addKeysToAgent = "yes";

    # Enable custom or temporary config without `home-manager switch`
    includes = [ "${sshDir}/config.local" ];

    # https://www.clear-code.com/blog/2023/4/3/recommended-ssh-config.html
    # https://gitlab.com/clear-code/ssh.d/-/blob/main/global.conf?ref_type=heads
    extraConfig = ''
      PasswordAuthentication no

      # default: "ask"
      StrictHostKeyChecking yes

      # https://serverfault.com/a/1109184/112217
      CheckHostIP no

      # `UseKeychain` only provided by darwin ssh agent, in Linux and pkgs.openssh, it isn't
      IgnoreUnknown UseKeychain
      UseKeychain yes
    '';

    # No problem to register the same *.pub in different services
    matchBlocks = {
      # ANYONE can access the registered public key at https://github.com/kachick.keys
      "github.com" = sharedConfig;

      # ANYONE can access the registered public key at https://gitlab.com/kachick.keys
      "gitlab.com" = sharedConfig;

      # Need authentication to get the public keys
      #   - https://stackoverflow.com/questions/23396870/can-i-get-ssh-public-key-from-url-in-bitbucket
      #   - https://developer.atlassian.com/cloud/bitbucket/rest/api-group-ssh/#api-users-selected-user-ssh-keys-get
      "bitbucket.org" = sharedConfig;

      # For WSL2 instances like default Ubuntu and podman-machine
      "localhost" = sharedConfig // {
        extraOptions = {
          StrictHostKeyChecking = "no";
          UserKnownHostsFile = "/dev/null";
        };
      };
    };
  };
}
