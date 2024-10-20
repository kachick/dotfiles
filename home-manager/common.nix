{
  config,
  pkgs,
  lib,
  edge-pkgs,
  homemade-pkgs,
  ...
}:

{
  imports = [
    ./bash.nix
    ./zsh.nix
    ./fish.nix
    ./pgp.nix
    ./ssh.nix
    ./git.nix
    ./editors.nix
    ./terminals.nix
    ./fzf.nix
    ./firefox.nix
    ./linux.nix
    ./darwin.nix
  ];

  # home.username = "<UPDATE_ME_IN_FLAKE>";
  # TODO: How to cover lima? The default is /home/kachick.local
  home.homeDirectory =
    if pkgs.stdenv.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/misc/xdg.nix
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
    stateVersion = "24.05";
    enableNixpkgsReleaseCheck = true;

    sessionVariables = {
      PAGER = "less";

      # https://github.com/sharkdp/bat/blob/v0.24.0/README.md?plain=1#L201-L219
      MANPAGER = "${lib.getExe pkgs.bashInteractive} -c '${pkgs.util-linux}/bin/col -bx | ${lib.getExe pkgs.bat} -l man -p'";
      MANROFFOPT = "-c";

      # - You can check the candidates in `locale -a`
      # - pkgs.glibc installs many candidates, but it does not support darwin
      # This value may overrides NixOS config for GNOME
      # LANG = "en_US.UTF-8";

      # NOTE: Original comments in zsh
      # Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
      # Remove -X and -F (exit if the content fits on one screen) to enable it.
      LESS = "-F -g -i -M -R -S -w -X -z-4";

      # https://github.com/coreos/bugs/issues/365#issuecomment-105638617
      LESSCHARSET = "utf-8";

      STACK_XDG = "https://github.com/commercialhaskell/stack/blob/72f0a1273dd1121740501a159988fc23df2fb362/doc/stack_root.md?plain=1#L7-L11";

      # Don't add needless quotation in the arguments. For example `gopass show 'rclone'` does not work. It should be `gopass show rclone`.
      RCLONE_PASSWORD_COMMAND = "${lib.getExe pkgs.gopass} show rclone";

      STARSHIP_CONFIG = ../config/starship/starship.toml;
    };

    sessionPath = [
      # Put executable for temporary use
      "${config.xdg.dataHome}/tmpbin"
    ];

    packages = import ./packages.nix {
      inherit pkgs;
      inherit edge-pkgs;
      inherit homemade-pkgs;
    };

    # https://wiki.archlinux.jp/index.php/%E3%83%AD%E3%82%B1%E3%83%BC%E3%83%AB
    # https://github.com/nix-community/home-manager/blob/fe56302339bb28e3471632379d733547caec8103/modules/home-environment.nix#L11
    language = {
      base = "ja_JP.UTF-8";
      time = "en_DK.UTF-8"; # To prefer ISO 8601 format. See https://unix.stackexchange.com/questions/62316/why-is-there-no-euro-english-locale
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  ## Needless the nix config here, because it is already configured by DeterminateSystems/nix-installer
  # https://github.com/nix-community/home-manager/blob/36f873dfc8e2b6b89936ff3e2b74803d50447e0a/modules/misc/nix.nix#L5
  # nix

  programs.lesspipe.enable = true;

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/direnv.nix
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

  programs.zoxide = {
    enable = true;

    # Use same nixpkgs channel as same as fzf
  };

  # No home-manager module exists https://github.com/nix-community/home-manager/issues/2890
  # TODO: Automate that needs to call `Install-Module -Name PSFzfHistory` first
  xdg.configFile."powershell/Microsoft.PowerShell_profile.ps1".source = ../config/powershell/Profile.ps1;

  xdg.dataFile."tmpbin/.keep".text = "";

  home.file.".hushlogin".text = "This file disables daily login message. Not depend on this text.";

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/starship.nix
  programs.starship = {
    enable = true;
  };

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/yazi.nix
  # TODO: Use shell integrations for `y` after release-24.11. 24.05 is using fixed old `ya`
  programs.yazi = {
    enable = true;
    settings = {
      manager = {
        sort_dir_first = true;
      };
    };
  };

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/bat.nix
  programs.bat = {
    enable = true;

    config = {
      # Candidates: preview: bat --list-themes | fzf --preview='bat --theme={} --color=always flake.nix'
      theme = "Nord";

      style = "plain";

      wrap = "character";
    };
  };

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/zellij.nix
  programs.zellij = {
    enable = true;

    # Don't use settings, nix and KDL is much unfit: https://github.com/NixOS/nixpkgs/issues/198655#issuecomment-1453525659
  };
  xdg.configFile."zellij" = {
    source = ../config/zellij;
    recursive = true;
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
}
