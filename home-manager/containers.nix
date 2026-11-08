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

      # Why not need a NixOS module (security.wrappers setcap) for cntr:
      # Upstream docs suggest root or setcap ('cap_sys_admin,cap_sys_chroot=ep') for Docker/rootful setups.
      # However, rootless Podman runs in a separate user namespace. Root or setcap binaries cannot see or enter
      # user-owned namespaces cleanly (see https://github.com/Mic92/cntr/issues/172).
      # Running cntr via 'podman unshare' enters the container's user namespace with full capabilities,
      # and setting CNTR_BASE_DIR to a user-writable path avoids needing host root or setcap permissions entirely.
      pinned.cntr
      (writeShellApplication {
        name = "podman-cntr";
        runtimeInputs = [
          podman
          pinned.cntr
        ];
        text = ''
          CNTR_BASE_DIR="''${CNTR_BASE_DIR:-''${XDG_RUNTIME_DIR:-/tmp}/cntr}"
          export CNTR_BASE_DIR
          mkdir -p "$CNTR_BASE_DIR"
          exec podman unshare env CNTR_BASE_DIR="$CNTR_BASE_DIR" cntr "$@"
        '';
        meta.description = "Attach to rootless podman containers using cntr";
      })

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
