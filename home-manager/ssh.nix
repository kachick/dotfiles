{
  pkgs,
  lib,
  config,
  ...
}:

let
  # SSH files cannot use XDG Base Directory.
  # I don't have permission to read https://bugzilla.mindrot.org/show_bug.cgi?id=2050, but several sources tells us, it is the answer
  #   - https://wiki.archlinux.jp/index.php/XDG_Base_Directory
  #   - https://superuser.com/a/1606519/120469
  sshDir = "${config.home.homeDirectory}/.ssh";
  localKnownHostsPath = "${sshDir}/known_hosts.local";
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
          GOPASS_GPG_BINARY = lib.getExe pkgs.sequoia-chameleon-gnupg;
        };
      }
    );
  };

  home.file."${sshDir}/control/.keep".text = "Make ControlPath shorter";

  home.activation = {
    ensureWritableKnownHosts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run touch '${localKnownHostsPath}'
    '';
  };
  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/programs/ssh.nix
  programs.ssh = {
    enable = true;

    # See https://github.com/nix-community/home-manager/pull/7655 for background
    enableDefaultConfig = false;

    # Enable custom or temporary config without `home-manager switch`
    includes = [ "${sshDir}/config.local" ];

    # https://www.clear-code.com/blog/2023/4/3/recommended-ssh-config.html
    # https://gitlab.com/clear-code/ssh.d/-/blob/main/global.conf?ref_type=heads
    extraConfig = ''
      PasswordAuthentication no

      # default: "ask"
      # Candidates: "accept-new". Don't use "no" as possible
      StrictHostKeyChecking yes

      # `UseKeychain` only provided by darwin ssh agent, in Linux and pkgs.openssh, it isn't
      IgnoreUnknown UseKeychain
      UseKeychain yes
    '';

    # You should consider the order of entries. ssh_config(client) prefers `first wins last`. It means fallbacking `*` should be last.
    # Realizing the ordering can not be done in Nix's attribute set. `DAG` by home-manager will be required for this purpose.
    #   - https://github.com/nix-community/home-manager/blob/295d90e22d557ccc3049dc92460b82f372cd3892/modules/programs/ssh.nix#L100-L102
    #   - https://github.com/nix-community/home-manager/blob/295d90e22d557ccc3049dc92460b82f372cd3892/modules/programs/ssh.nix#L531-L547
    matchBlocks =
      let
        hosts =
          let
            # You can register the same *.pub in different services
            gitHostingService = {
              identityFile = "${sshDir}/id_ed25519";
              identitiesOnly = true;
              user = "git";
            };
          in
          {
            # ANYONE can access the registered public key at https://github.com/kachick.keys
            "github.com" = lib.hm.dag.entryBefore [ "*" ] gitHostingService;

            # ANYONE can access the registered public key at https://gitlab.com/kachick.keys
            "gitlab.com" = lib.hm.dag.entryBefore [ "*" ] gitHostingService;

            # Need authentication to get the public keys
            #   - https://stackoverflow.com/questions/23396870/can-i-get-ssh-public-key-from-url-in-bitbucket
            #   - https://developer.atlassian.com/cloud/bitbucket/rest/api-group-ssh/#api-users-selected-user-ssh-keys-get
            "bitbucket.org" = lib.hm.dag.entryBefore [ "*" ] gitHostingService;

            # For WSL2 instances like default Ubuntu and podman-machine
            "localhost" = lib.hm.dag.entryBefore [ "*" ] (
              gitHostingService
              // {
                extraOptions = {
                  StrictHostKeyChecking = "ask";
                  UserKnownHostsFile = "/dev/null";
                };
              }
            );
          };

        domains = {
          # mDNS via avahi.
          "*.local" = lib.hm.dag.entryBetween [ "*" ] [ "localhost" ] {
            extraOptions = {
              # NixOS rebuilds change the host key
              StrictHostKeyChecking = "accept-new";
            };
          };
        };

        fallbacks = {
          "*" = {
            # https://groups.google.com/g/opensshunixdev/c/e5-kTKpxcaI/m/bdVNyL4BBAAJ
            hashKnownHosts = false;

            # - It accepts multiple files separated by whitespace. See https://man.openbsd.org/ssh_config#UserKnownHostsFile for detail
            # - First path should be writable for the `StrictHostKeyChecking != yes` use-case
            userKnownHostsFile = "${localKnownHostsPath} ${../config/ssh/known_hosts}";

            # unit: seconds
            serverAliveInterval = 60;

            forwardAgent = true;

            controlMaster = "auto";
            controlPersist = "10m";
            # Used %r by default. And it makes `ControlPath too long` especially using upterm.
            # See following resources and GH-1030
            # https://github.com/nix-community/home-manager/blob/20665c6efa83d71020c8730f26706258ba5c6b2a/modules/programs/ssh.nix#L424-L430
            # https://github.com/owenthereal/upterm/issues/283#issuecomment-2508582116
            # And just avoiding %r is not enough for `tailscale ssh`. So, only use %C to avoid it.
            # https://gist.github.com/andyvanee/bcf95b1044b80e72b4a42933549a079b
            controlPath = "~/.ssh/control/%C";

            addKeysToAgent = "yes";

            # https://serverfault.com/a/1109184/112217
            checkHostIP = "no";
          };
        };
      in
      hosts // domains // fallbacks;
  };
}
