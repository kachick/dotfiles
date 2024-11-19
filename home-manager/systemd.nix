{ pkgs, lib, ... }:

{
  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/systemd.nix#L161-L173
  systemd = {
    user = {
      # Enable locale for GNOME and terminals in the gnome-shell. Linux VT console respects home.sessionVariables instead
      # https://superuser.com/a/1841368
      # https://github.com/nix-community/home-manager/blob/5ec753a1fc4454df9285d8b3ec0809234defb975/modules/systemd.nix#L92-L96
      sessionVariables = {
        # GNOME clock respects LC_TIME. And does not support displaying iso-8601 format even if set en_DK
        LC_TIME = "ja_JP.UTF-8";
      };

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
  };
}
