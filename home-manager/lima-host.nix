{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.ssh.includes = [
    # * lima does not support XDG spec. https://github.com/lima-vm/lima/discussions/2745#discussioncomment-10958677
    # * adding this as `ssh -F` makes it possible to use ssh login, it is required for `ms-vscode-remote.remote-ssh`
    # * the content of file will be changed for each instance creation
    "${config.home.homeDirectory}/.lima/default/ssh.config"
  ];

  home = {
    activation = {
      # Required to avoid missing systemctl in NixOS
      # https://github.com/lima-vm/lima/blob/9248baf14a3208249ed38179cdd018ec288d1ef5/pkg/autostart/autostart.go#L91-L92
      registerStartingLima =
        if pkgs.stdenv.hostPlatform.isLinux then
          (lib.hm.dag.entryBefore [ "reloadSystemd" ] ''
            PATH="$PATH:${lib.getBin pkgs.systemd}/bin" run ${lib.getBin pkgs.lima}/bin/limactl start-at-login --enabled
          '')
        else
          (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run ${lib.getBin pkgs.lima}/bin/limactl start-at-login --enabled
          '');
    };
  };
}
