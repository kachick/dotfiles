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
}
