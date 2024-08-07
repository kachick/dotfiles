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
    ./gpg.nix
    ./ssh.nix
    ./git.nix
    ./editor.nix
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
      # Do NOT set GIT_EDITOR, it overrides `core.editor` in git config
      # https://unix.stackexchange.com/questions/4859/visual-vs-editor-what-s-the-difference
      EDITOR = lib.getExe pkgs.micro; # If you forgot the keybind: https://github.com/zyedidia/micro/blob/c15abea64c20066fc0b4c328dfabd3e6ba3253a0/runtime/help/defaultkeys.md
      VISUAL = lib.getExe pkgs.micro; # vscode is heavy even if in VISUAL use
      PAGER = "less";

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
  };

  # This also changes xdg? Official manual sed this config is better for non NixOS Linux
  # https://github.com/nix-community/home-manager/blob/559856748982588a9eda6bfb668450ebcf006ccd/modules/targets/generic-linux.nix#L16
  targets.genericLinux.enable = pkgs.stdenv.isLinux;

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

  # https://nixos.wiki/wiki/Home_Manager
  #   - Prefer XDG_*
  #   - If can't write the reason as a comment

  # Do not alias *.nix into `xdg.configFile`, it actually cannot be used because of using many relative dirs
  # So you should call `home-manager switch` with `-f ~/repos/dotfiles/USER_NAME.nix`

  xdg.configFile."wezterm" = {
    source = ../config/wezterm;
    recursive = true;
  };

  xdg.configFile."alacritty/alacritty.toml".source = ../config/alacritty/alacritty-unix.toml;
  xdg.configFile."alacritty/unix.toml".source =
    if pkgs.stdenv.isDarwin then ../config/alacritty/macos.toml else ../config/alacritty/linux.toml;
  xdg.configFile."alacritty/common.toml".source = ../config/alacritty/common.toml;
  xdg.configFile."alacritty/themes" = {
    source = ../config/alacritty/themes;
    recursive = true;
  };

  # Not under "starship/starship.toml"
  xdg.configFile."starship.toml".source = ../config/starship/starship.toml;

  # No home-manager module exists https://github.com/nix-community/home-manager/issues/2890
  # TODO: Automate that needs to call `Install-Module -Name PSFzfHistory` first
  xdg.configFile."powershell/Microsoft.PowerShell_profile.ps1".source = ../config/powershell/Profile.ps1;

  # https://github.com/NixOS/nixpkgs/issues/222925#issuecomment-1514112861
  xdg.configFile."autostart/userdirs.desktop".text = ''
    [Desktop Entry]
    Exec=xdg-user-dirs-update
    TryExec=xdg-user-dirs-update
    NoDisplay=true
    StartupNotify=false
    Type=Application
    X-KDE-AutostartScript=true
    X-KDE-autostart-phase=1
  '';

  # https://wiki.archlinux.org/title/wayland
  # Didn't work if the electron is bundled, so unfit for nixpkgs distributing apps
  # xdg.configFile."electron-flags.conf".text = ''
  #   --enable-features=UseOzonePlatform
  #   --ozone-platform=wayland
  #   --enable-wayland-ime
  # '';

  xdg.dataFile."tmpbin/.keep".text = "";

  home.file.".hushlogin".text = "This file disables daily login message. Not depend on this text.";

  # Should have `root = true` in the file. - https://github.com/kachick/anylang-template/blob/45d7ef685ac4fd3836c3b32b8ce8fb45e909b771/.editorconfig#L1
  # Intentionally avoided to use https://github.com/nix-community/home-manager/blob/f58889c07efa8e1328fdf93dc1796ec2a5c47f38/modules/misc/editorconfig.nix
  home.file.".editorconfig".source =
    pkgs.fetchFromGitHub {
      owner = "kachick";
      repo = "anylang-template";
      rev = "45d7ef685ac4fd3836c3b32b8ce8fb45e909b771";
      sha256 = "sha256-F8xP4xCIS1ybvRm1xGB2USekGWKKxz0nokpY6gRxKBE=";
    }
    + "/.editorconfig";

  xdg.configFile."fcitx5/config" = {
    source = ../config/fcitx5/config;
  };
  xdg.configFile."fcitx5/profile" = {
    source = ../config/fcitx5/profile;
  };

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/fzf.nix
  # https://github.com/junegunn/fzf/blob/master/README.md
  programs.fzf = rec {
    enable = true;

    # https://github.com/junegunn/fzf/blob/d579e335b5aa30e98a2ec046cb782bbb02bc28ad/README.md#respecting-gitignore
    defaultCommand = "${pkgs.fd}/bin/fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";

    defaultOptions = [
      # --walker*: Default file filtering will be changed by this option if FZF_DEFAULT_COMMAND is not set: https://github.com/junegunn/fzf/pull/3649/files
      "--walker-skip '.git,node_modules,.direnv,vendor,dist'"
    ];

    # CTRL+T
    fileWidgetCommand = defaultCommand;
    fileWidgetOptions = [
      "--preview '${pkgs.bat}/bin/bat --color=always {}'"
      "--preview-window '~3'"
    ];

    # ALT-C
    changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d";
    changeDirWidgetOptions = [ "--preview '${pkgs.eza}/bin/eza --color=always --tree {} | head -200'" ];

    colors = {
      # See #295 for the detail
      "bg+" = "#005f5f";
    };
  };

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/starship.nix
  programs.starship = {
    enable = true;
  };

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/bat.nix
  programs.bat = {
    enable = true;

    config = {
      # Candidates: bat --list-themes
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
}
