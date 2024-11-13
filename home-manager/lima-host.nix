{ config, ... }:
{
  programs.ssh.includes = [
    # * lima does not support XDG spec. https://github.com/lima-vm/lima/discussions/2745#discussioncomment-10958677
    # * adding this as `ssh -F` makes it possible to use ssh login, it is required for `ms-vscode-remote.remote-ssh`
    # * the content of file will be changed for each instance creation
    "${config.home.homeDirectory}/.lima/default/ssh.config"
  ];
}
