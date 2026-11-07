{
  config,
  pkgs,
  lib,
  ...
}:
let
  lima = pkgs.local.lima-full;
in
{
  programs.ssh.includes = [
    # * lima does not support XDG spec. https://github.com/lima-vm/lima/discussions/2745#discussioncomment-10958677
    # * adding this as `ssh -F` makes it possible to use ssh login, it is required for `ms-vscode-remote.remote-ssh`
    # * the content of file will be changed for each instance creation
    "${config.home.homeDirectory}/.lima/*/ssh.config"
  ];

  home = {
    packages = [
      # lima package includes qemu in the PATH.
      # But it is required to specify qemu in your Linux. See GH-1049 and NixOS config for details.
      lima
    ];

    # Lima and the yaml config does not have importing feature. However it prefers some files to realize overriding.
    # See https://github.com/lima-vm/lima/blob/v1.0.1/templates/default.yaml#L536-L574 for details
    file.".lima/_config/default.yaml".source = ../config/lima/_config/default.yaml;

    sessionVariables = {
      LIMA_INSTANCE = "docker-nix";
    };

    shellAliases = {
      "lc" = "limactl";
    };

    activation = {
      # Required to avoid missing systemctl in NixOS
      # https://github.com/lima-vm/lima/blob/v2.3.0/pkg/autostart/systemd/systemd.go#L44-L48
      registerStartingLima = lib.hm.dag.entryBefore [ "reloadSystemd" ] ''
        run ${
          pkgs.lib.getExe (
            pkgs.writeShellApplication {
              name = "register-lima-service";
              text = ''
                target_instance="''${LIMA_INSTANCE:-${config.home.sessionVariables.LIMA_INSTANCE}}"
                if [ -n "$target_instance" ] && limactl list --quiet | grep -Fqx "$target_instance"; then
                  limactl autostart enable "$target_instance"
                fi
              '';
              meta.description = "Ensure mandatory $PATH when run lima helper command";
              runtimeInputs = [
                pkgs.systemd
                pkgs.gnugrep
                config.programs.ssh.package # Ensure the path before lima executables. See https://github.com/lima-vm/lima/pull/3637 for background
                lima
              ];
            }
          )
        }
      '';
    };
  };
}
