{
  pkgs,
  lib,
  ...
}:

{
  home = {
    packages = with pkgs; [
      # - Linux package does not contain podman-remote, you should install uidmap with apt and use this podman as actual engine
      #   https://github.com/NixOS/nixpkgs/blob/194846768975b7ad2c4988bdb82572c00222c0d7/pkgs/applications/virtualization/podman/default.nix#L112-L116
      podman
      podman-tui
      docker-compose

      kubectl
      stern
      k9s
    ];
  };

  programs = {
    bash.initExtra = ''
      source "${pkgs.podman}/share/bash-completion/completions/podman"
      source "${pkgs.kubectl}/share/bash-completion/completions/kubectl.bash"
    '';

    zsh.initContent = lib.mkOrder 1001 ''
      source "${pkgs.podman}/share/zsh/site-functions/_podman"
      source "${pkgs.kubectl}/share/zsh/site-functions/_kubectl"
    '';
  };

  systemd.user = {
    services.podman = {
      Unit = {
        Description = "Podman API Service";
        Requires = [ "podman.socket" ];
        After = [ "podman.socket" ];
        Documentation = "man:podman-system-service(1)";
        StartLimitIntervalSec = 0;
      };
      Service = {
        Type = "exec";
        KillMode = "process";
        Environment = ''LOGGING=" --log-level=info"'';
        ExecStart = [
          ""
          "${lib.getExe pkgs.podman} $LOGGING system service"
        ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # execute by `systemctl --user start podman.socket`
    #
    # Required by podman-tui and docker-compose
    # https://github.com/containers/podman/blob/58c8803a1e01975dff19782f29a99536e3b2fe02/docs/tutorials/socket_activation.md
    sockets.podman = {
      Unit = {
        Description = "Podman API Socket";
        Documentation = "man:podman-system-service(1)";
      };
      Socket = {
        ListenStream = "%t/podman/podman.sock";
        SocketMode = 660;
      };
      Install.WantedBy = [ "sockets.target" ];
    };
  };
}
