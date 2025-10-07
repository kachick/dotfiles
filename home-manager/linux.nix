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

      # Workaround for rust-analyzer error: "ERROR can't load standard library, try installing `rust-src`"
      RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
    };

    # Putting files into xdg.userDirs.templates enables new file menu on Nautilus
    # https://askubuntu.com/a/209669
    file."Templates/blank.md".text = "";

    packages =
      (with pkgs; [
        # Fix missing locales as `locale: Cannot set LC_CTYPE to default locale`
        glibc

        # https://github.com/nix-community/home-manager/blob/a8f8f48320c64bd4e3a266a850bbfde2c6fe3a04/modules/services/ssh-agent.nix#L37
        openssh

        iputils # `ping` etc

        # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/iw/iw/package.nix
        iw # replacement of wireless-tools(iwconfig)

        dysk # alt df. Only works on Linux. See https://github.com/NixOS/nixpkgs/pull/400833

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

        # Enable LSP on global.
        #   - nixd is useually required in all platforms even in WSL2
        #   - Especially zed-editor is using for NixOS default VISUAL editor. It requires LSPs
        nixd
        unstable.typos-lsp
        gopls
        rust-analyzer
        rustfmt

        shellcheck
        shfmt

        # Useful if facing to coredump likely https://github.com/NixOS/nixpkgs/pull/423716
        # Simply use built-in TUI as following
        #
        # ```console
        # > lldb --core the.dump
        # > (lldb) gui
        # ```
        #
        # coredump can be output with `coredumpctl list` and `coredumpctl dump <ID> --output path`
        #
        # LLDB also works on macOS, however omit it to keep lightweight and small dependencies
        lldb

        # TODO: Prefer stable channel since nixos-25.11
        # While using unstable channel, don't add this into macOS dependency. It seems flaky now. See https://github.com/kachick/dotfiles/pull/1295#issuecomment-3377995351
        # Available since https://github.com/NixOS/nixpkgs/pull/409075
        unstable.msedit # `edit`

        patched.gemini-cli-bin
      ])
      ++ (with pkgs.my; [
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

    zsh.initContent = lib.mkOrder 1001 ''
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

      # mozc_tool can be run with `/run/current-system/sw/lib/mozc/mozc_tool --mode=config_dialog` on NixOS
      #
      # You should run `ibus write-cache; ibus restart` after changed the ibus config
      # See https://github.com/google/mozc/blob/2.31.5712.102/docs/configurations.md for detail
      "mozc/ibus_config.textproto".source = ../config/mozc/ibus_config.textproto;
      # You should manually load the custom keymap if changed. Because of mozc_tool does not support CLI and rc files
      "mozc/keymap-msime-customized.txt".source = ../config/mozc/keymap-msime-customized.txt;
    };
  };
}
