{ pkgs, ... }:

{
  # https://github.com/nix-community/home-manager/blob/master/modules/services/gpg-agent.nix
  services.gpg-agent.enable = true;

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/gpg.nix
  programs.gpg = {
    enable = true;

    # https://groups.google.com/g/opensshunixdev/c/e5-kTKpxcaI/m/bdVNyL4BBAAJ
    hashKnownHosts = false;
    userKnownHostsFile = "${sshDir}/known_hosts";

    # unit: seconds
    serverAliveInterval = 60;

    forwardAgent = true;

    controlMaster = "auto";
    controlPersist = "10m";

    # Enable custom or temporary config without `home-manager switch`
    includes = [
      "${sshDir}/config.local"
    ];

    # https://www.clear-code.com/blog/2023/4/3/recommended-ssh-config.html
    # https://gitlab.com/clear-code/ssh.d/-/blob/main/global.conf?ref_type=heads
    extraConfig = ''
      AddKeysToAgent yes

      PasswordAuthentication no

      # default: "ask" - I'm disabling it for now
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
      "github.com" = {
        identityFile = "${sshDir}/id_ed25519";
        identitiesOnly = true;
        user = "git";
      };

      # ANYONE can access the registered public key at https://gitlab.com/kachick.keys
      "gitlab.com" = {
        identityFile = "${sshDir}/id_ed25519";
        identitiesOnly = true;
        user = "git";
      };

      # Need authentication to get the public keys
      #   - https://stackoverflow.com/questions/23396870/can-i-get-ssh-public-key-from-url-in-bitbucket
      #   - https://developer.atlassian.com/cloud/bitbucket/rest/api-group-ssh/#api-users-selected-user-ssh-keys-get
      "bitbucket.org" = {
        identityFile = "${sshDir}/id_ed25519";
        identitiesOnly = true;
        user = "git";
      };
    };
  };
}
