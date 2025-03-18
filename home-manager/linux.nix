{
  config,
  pkgs,
  lib,
  ...
}:

{
  home = {
    homeDirectory = lib.mkDefault "/home/${config.home.username}";

    sessionVariables = {
      # Don't add needless quotation in the arguments. For example `gopass show 'rclone'` does not work. It should be `gopass show rclone`.
      RCLONE_PASSWORD_COMMAND = "${lib.getExe pkgs.gopass} show rclone";
    };

    packages =
      (with pkgs; [
        # Fix missing locales as `locale: Cannot set LC_CTYPE to default locale`
        glibc

        # https://github.com/nix-community/home-manager/blob/a8f8f48320c64bd4e3a266a850bbfde2c6fe3a04/modules/services/ssh-agent.nix#L37
        openssh

        iputils # `ping` etc

        # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/iw/iw/package.nix
        iw # replacement of wireless-tools(iwconfig)

        rclone

        # - Enable special module for Nix OS.
        # - Linux package does not contain podman-remote, you should install uidmap with apt and use this podman as actual engine
        #   https://github.com/NixOS/nixpkgs/blob/194846768975b7ad2c4988bdb82572c00222c0d7/pkgs/applications/virtualization/podman/default.nix#L112-L116
        podman
        podman-tui
        docker-compose

        kubectl
        stern
        k9s

        tailscale # Frequently backported to stable channel

        # Keybindigs: https://git.sr.ht/~bptato/chawan/tree/master/item/res/config.toml
        chawan # `cha`
      ])
      ++ (with pkgs.my; [
        renmark # Depend on chawan
        rclone-list-mounted
        rclone-mount
        rclone-fzf
      ]);
  };

  programs = {
    bash.initExtra = ''
      source "${pkgs.podman}/share/bash-completion/completions/podman"
      source "${pkgs.kubectl}/share/bash-completion/completions/kubectl.bash"
    '';

    zsh.initExtra = ''
      source "${pkgs.podman}/share/zsh/site-functions/_podman"
      source "${pkgs.kubectl}/share/zsh/site-functions/_kubectl"
    '';
  };

  # xdg-user-dirs NixOS module does not work or is not enough for me to keep English dirs even in Japanese locale.
  # Check your `~/.config/user-dirs.dirs` if you faced any trouble
  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/misc/xdg-user-dirs.nix
  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;
    };

    configFile = {
      "hypr/hyprland.conf".source = ../config/hyprland/hyprland.conf;

      # https://github.com/NixOS/nixpkgs/issues/222925#issuecomment-1514112861
      "autostart/userdirs.desktop".text = ''
        [Desktop Entry]
        Exec=xdg-user-dirs-update
        TryExec=xdg-user-dirs-update
        NoDisplay=true
        StartupNotify=false
        Type=Application
        X-KDE-AutostartScript=true
        X-KDE-autostart-phase=1
      '';

      # Should sync with the directory instead of each file. See https://github.com/nix-community/home-manager/issues/3090#issuecomment-1799268943
      fcitx5 = {
        source = ../config/fcitx5;
      };
    };
  };
}
