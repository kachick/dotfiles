{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./bash.nix
    ./zsh.nix
    ./encryption.nix
    ./ssh.nix
    ./git.nix
    ./editors.nix
    ./terminals.nix
    ./fzf.nix
    ./television.nix
    ./telemetry.nix
  ];

  # home.username = "<UPDATE_ME_IN_FLAKE>";

  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/misc/xdg.nix
  xdg.enable = true;

  home = {
    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    #
    # TODO: Bump to 25.11 *carefully* once both NixOS and Home Manager 25.11 are out.
    #       This setting is similar to but not identical in purpose to NixOS’s `system.stateVersion`.
    stateVersion = "25.05";
    enableNixpkgsReleaseCheck = true;

    sessionVariables = {
      PAGER = "less";

      # https://github.com/sharkdp/bat/blob/v0.24.0/README.md?plain=1#L201-L219
      MANPAGER = "${lib.getExe pkgs.bashInteractive} -c '${lib.getExe' pkgs.util-linux "col"} -bx | ${lib.getExe pkgs.bat} -l man -p'";
      MANROFFOPT = "-c";

      # NOTE: Original comments in zsh
      # - Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
      # - Remove -X and -F (exit if the content fits on one screen) to enable it.
      #
      # Don't add -S to enable wrap
      LESS = "-F -g -i -M -R -w -X -z-4";

      # https://github.com/coreos/bugs/issues/365#issuecomment-105638617
      LESSCHARSET = "utf-8";

      STACK_XDG = "https://github.com/commercialhaskell/stack/blob/72f0a1273dd1121740501a159988fc23df2fb362/doc/stack_root.md?plain=1#L7-L11";

      # NOTE: Setting in this variable might be unuseful, because of home-manager session variables will not be changed on GNOME except re-login
      # Workaround is `export STARSHIP_CONFIG="$(fd --absolute-path starship.toml)"` while developing
      STARSHIP_CONFIG = "${../config/starship/starship.toml}";

      # Workaround to detect tailscale kyes
      # Setting this is not an ideal state. Because of this env ignores configs on $PWD
      # Reconsider to use trufflehog if core maintainers no longer review https://github.com/gitleaks/gitleaks/pull/1808
      GITLEAKS_CONFIG = "${../config/gitleaks/.gitleaks.toml}";
    };

    sessionPath = [
      # Put executable for temporary use
      "${config.xdg.dataHome}/tmpbin"
    ];

    packages = import ./packages.nix {
      inherit pkgs;
    };

    # You can check the candidates in `locale -a`
    # pkgs.glibc installs many candidates, but it does not support darwin
    # https://wiki.archlinux.jp/index.php/%E3%83%AD%E3%82%B1%E3%83%BC%E3%83%AB
    # https://github.com/nix-community/home-manager/blob/fe56302339bb28e3471632379d733547caec8103/modules/home-environment.nix#L11
    language = {
      base = "ja_JP.UTF-8";
      # Don't set another locale such as time here, it makes unstable behaviors even if I set it in environment.d
      # So if required them, it should be specified in each shell rc files. See GH-1116 for detail
    };

    # Prefer this rather than adding wrapped script to make zsh possible to complete
    # Take care if I you adding nushell in the Unix dependencies again
    shellAliases = {
      "g" = "git";

      # https://github.com/NixOS/nixpkgs/pull/344193
      "zed" = "zeditor";

      # https://www.reddit.com/r/NixOS/comments/yr3jje/comment/ivswbex/
      "sudoc" = "sudo --preserve-env=PATH env";

      "gH" = "git show HEAD";

      # GH-897
      "ddis" = "direnv disallow";

      # NOTE: If the logs about missing `bind` implementations are noisy and cannot be suppressed individually,
      #       adding `--disable-event unimplemented` might be required.
      #
      # Highlighting is still experimental. However, this is a core requirement for me: https://github.com/kachick/times_kachick/issues/184#issuecomment-1396670990
      "br" = "brush --enable-highlighting";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  ## Needless the nix config here, because it is already configured by DeterminateSystems/nix-installer
  # https://github.com/nix-community/home-manager/blob/36f873dfc8e2b6b89936ff3e2b74803d50447e0a/modules/misc/nix.nix#L5
  # nix

  programs.lesspipe.enable = true;

  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/programs/direnv.nix
  programs.direnv = {
    enable = true;

    config.global = {
      # https://github.com/direnv/direnv/issues/68#issuecomment-2054033048
      hide_env_diff = true;
    };

    # Replacement of `programs.direnv.enableNixDirenvIntegration = true;`
    #
    # Make much faster, but I may add nix_direnv_watch_file in several repositories when it has `.ruby-version`
    # See following reference
    #   - https://github.com/nix-community/nix-direnv/blob/ed2cb75553b4864e3c931a48e3a2cd43b93152c5/README.md?plain=1#L368-L373
    #   - https://github.com/kachick/ruby-ulid/pull/410
    nix-direnv = {
      enable = true;
    };
  };

  # https://github.com/nix-community/home-manager/blob/release-25.05/modules/programs/zoxide.nix
  programs.zoxide = {
    enable = true;
    # Using unstable to apply https://github.com/ajeetdsouza/zoxide/pull/1048. Prefer stable since nixos-25.11
    package = pkgs.unstable.zoxide;

    # Use same nixpkgs channel as same as fzf since nixos-25.11
  };

  # No home-manager module exists https://github.com/nix-community/home-manager/issues/2890
  # TODO: Automate that needs to call `Install-Module -Name PSFzfHistory` first
  xdg.configFile."powershell/Microsoft.PowerShell_profile.ps1".source =
    ../config/powershell/Profile.ps1;

  # Don't use nushell Nix modules. Because of the interface and API is much unstable
  # I prefer to use stable home-manager channel. So nushell integration should be done manually
  #
  # Don't use `recursive` here. We can't expect any nushell changes for now
  xdg.configFile."nushell/env.nu".source = ../config/nushell/env.nu;
  xdg.configFile."nushell/config.nu".source = ../config/nushell/config.nu;
  xdg.configFile."nushell/unix_config.nu".source = ../config/nushell/unix_config.nu;

  # I'm unsure why this file will work on NixOS. It is a customization on Arch and I coudn't find the patches on nixpkgs
  # - https://github.com/electron/electron/issues/46473#issuecomment-2778637008
  # - https://wiki.archlinux.org/title/Chromium#Native_Wayland_support
  xdg.configFile."electron-flags.conf".source = ../config/electron/electron-flags.conf;

  xdg.dataFile."tmpbin/.keep".text = "";

  home.file.".hushlogin".text = "This file disables daily login message. Not depend on this text.";

  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/programs/starship.nix
  programs.starship = {
    enable = true;
  };

  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/programs/bat.nix
  programs.bat = {
    enable = true;

    config = {
      # Candidates: preview: bat --list-themes | fzf --preview='bat --theme={} --color=always flake.nix'
      theme = "Nord";

      style = "plain";

      wrap = "character";
    };
  };

  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/programs/zellij.nix
  programs.zellij = {
    enable = true;

    # Don't use settings, nix and KDL is much unfit: https://github.com/NixOS/nixpkgs/issues/198655#issuecomment-1453525659
  };
  xdg.configFile."zellij" = {
    source = ../config/zellij;
    recursive = true;
  };
  xdg.configFile."zellij/simplified-ui.kdl" = {
    text = builtins.readFile ../config/zellij/config.kdl + ''
      // Use a simplified UI without special fonts (arrow glyphs)
      // This is necessary on Linux VT to avoid Tofu
      // Or you can run zellij with `zellij options --simplified-ui true`
      simplified_ui true
    '';
  };

  # TODO: Switch to raw config file and shared in Windows
  programs.ripgrep = {
    enable = true;
    # https://github.com/BurntSushi/ripgrep/issues/623#issuecomment-659909044
    arguments = [
      "--hidden"
      "--glob"
      "!.git"
    ];
  };

  # https://github.com/nix-community/home-manager/blob/release-25.05/modules/programs/atuin.nix
  programs.atuin = {
    enable = true;

    flags = [
      # https://github.com/atuinsh/atuin/issues/51
      "--disable-up-arrow"

      "--disable-ctrl-r" # Keep fzf key-bindings
    ];

    settings = {
      # auto_sync = true; # TODO: Consider enabling after test

      # Don't use the actual address likely
      # sync_address = "http://algae.local:8888";
      # Because TLS support is disabled now. NixOS module seems not accepting config files and TSL support for now
      # Therefore using SSH forwarding for the HTTP instead of TLS support on atuin
      sync_address = "https://algae.local:58888";
    };
  };

  # https://github.com/nix-community/home-manager/blob/release-25.05/modules/programs/yazi.nix
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    settings = {
      # https://github.com/sxyazi/yazi/pull/2803
      # https://github.com/nix-community/home-manager/pull/7160
      mgr = {
        sort_dir_first = true;
      };
    };
  };
}
