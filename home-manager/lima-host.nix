{
  config,
  pkgs,
  lib,
  ...
}:
let
  lima = pkgs.patched.lima;
in
{
  programs.ssh.includes = [
    # * lima does not support XDG spec. https://github.com/lima-vm/lima/discussions/2745#discussioncomment-10958677
    # * adding this as `ssh -F` makes it possible to use ssh login, it is required for `ms-vscode-remote.remote-ssh`
    # * the content of file will be changed for each instance creation
    "${config.home.homeDirectory}/.lima/default/ssh.config"
  ];

  home = {
    packages = [
      # lima package includes qemu in the PATH.
      # But required to specify qemu in your Linux. See GH-1049 and NixOS config for detail.
      # As far as I know, not required the global qemu in darwin.
      lima
    ];

    # Lima and the yaml config does not have importing feature. However it prefers some files to realize overriding.
    # See https://github.com/lima-vm/lima/blob/v1.0.1/templates/default.yaml#L536-L574 for detail
    file.".lima/_config/default.yaml".source = ../config/lima/_config/default.yaml;

    shellAliases = {
      "lc" = "limactl";
    };

    activation = {
      # /tmp/lima will be writable shared by default of lima. However lima does not create the directory, and home-manager file module does not fit under /tmp.
      ensureLimaSharedTempdir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p /tmp/lima
        run touch /tmp/lima/.keep
      '';

      # Required to avoid missing systemctl in NixOS
      # https://github.com/lima-vm/lima/blob/9248baf14a3208249ed38179cdd018ec288d1ef5/pkg/autostart/autostart.go#L91-L92
      # In macOS, similar provision for /bin/launchctl
      registerStartingLima =
        if pkgs.stdenv.hostPlatform.isLinux then
          (lib.hm.dag.entryBefore [ "reloadSystemd" ] ''
            PATH="$PATH:${lib.getBin pkgs.systemd}/bin" run ${lib.getBin lima}/bin/limactl start-at-login --enabled
          '')
        else
          (lib.hm.dag.entryBefore [ "setupLaunchAgents" ] ''
            PATH="$PATH:/bin" run ${lib.getBin lima}/bin/limactl start-at-login --enabled
          '');
    };
  };
}
