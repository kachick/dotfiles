{ config, pkgs, ... }:

{
  imports = [
    ./packages.nix
    ./bash.nix
    ./zsh.nix
    ./fish.nix
    ./gpg.nix
    ./ssh.nix
    ./git.nix
    ./zellij.nix
    ./darwin.nix # Omit needless parts for Linux in the file
    ./homemade.nix
  ];

  # home.username = "<UPDATE_ME_IN_FLAKE>";
  # TODO: How to cover lima? The default is /home/kachick.local
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";

  # https://github.com/nix-community/home-manager/blob/master/modules/misc/xdg.nix
  xdg.enable = true;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";

  home = {
    sessionVariables = {
      # https://unix.stackexchange.com/questions/4859/visual-vs-editor-what-s-the-difference
      EDITOR = "micro"; # If you forgot the keybind: https://github.com/zyedidia/micro/blob/c15abea64c20066fc0b4c328dfabd3e6ba3253a0/runtime/help/defaultkeys.md
      VISUAL = "code -w";
      PAGER = "less";

      # - You can check the candidates in `locale -a`
      # - pkgs.glibc installs many candidates, but it does not support darwin
      LANG = "en_US.UTF-8";

      # NOTE: Original comments in zsh
      # Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
      # Remove -X and -F (exit if the content fits on one screen) to enable it.
      LESS = "-F -g -i -M -R -S -w -X -z-4";

      # https://github.com/coreos/bugs/issues/365#issuecomment-105638617
      LESSCHARSET = "utf-8";
    };

    sessionPath = [
      # See ./homemade.nix for detail
      "${config.xdg.dataHome}/homemade/bin"
    ];
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

  programs.direnv = {
    enable = true;

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
  };

  # https://nixos.wiki/wiki/Home_Manager
  #   - Prefer XDG_*
  #   - If can't write the reason as a comment

  # Do not alias *.nix into `xdg.configFile`, it actually cannot be used because of using many relative dirs
  # So you should call `home-manager switch` with `-f ~/repos/dotfiles/USER_NAME.nix`
  xdg.configFile."alacritty/common.toml".source = ../config/alacritty/common.toml;
  xdg.configFile."alacritty/alacritty.toml".source = ../config/alacritty/unix.toml;

  # Not under "starship/starship.toml"
  xdg.configFile."starship.toml".source = ../config/starship/starship.toml;

  home.file.".hushlogin".text = "This file disables daily login message. Not depend on this text.";

  # - stack manager can not found in https://github.com/nix-community/home-manager/tree/8d243f7da13d6ee32f722a3f1afeced150b6d4da/modules/programs
  # - https://github.com/kachick/dotfiles/issues/142
  home.file.".stack/config.yaml".source = ../config/stack/config.yaml;

  # Should have `root = true` in the file. - https://github.com/kachick/anylang-template/blob/45d7ef685ac4fd3836c3b32b8ce8fb45e909b771/.editorconfig#L1
  # Intentionally avoided to use https://github.com/nix-community/home-manager/blob/f58889c07efa8e1328fdf93dc1796ec2a5c47f38/modules/misc/editorconfig.nix
  home.file.".editorconfig".source =
    pkgs.fetchFromGitHub
      {
        owner = "kachick";
        repo = "anylang-template";
        rev = "45d7ef685ac4fd3836c3b32b8ce8fb45e909b771";
        sha256 = "sha256-F8xP4xCIS1ybvRm1xGB2USekGWKKxz0nokpY6gRxKBE=";
      }
    + "/.editorconfig"
  ;

  xdg.configFile."irb/irbrc".source =
    pkgs.fetchFromGitHub
      {
        owner = "kachick";
        repo = "irb-power_assert";
        rev = "98ad68b4c391bb30adee1ba119cb6c6ed5bd0bfc";
        sha256 = "sha256-Su3jaPELaBKa+CJpNp6OzOb/6/wwGk7JDxP/w9wVBtM=";
      }
    + "/examples/.irbrc"
  ;

  # typos does not have feature global config, this is used in git hooks for https://github.com/kachick/dotfiles/issues/412
  xdg.configFile."typos/_typos.toml".text = ''
    [default.extend-words]
    # https://github.com/crate-ci/typos/issues/415
    ba = "ba"
  '';

  programs.fzf = {
    enable = true;
  };

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/starship.nix
  programs.starship = {
    enable = true;
  };

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/mise.nix
  programs.mise = {
    enable = true;

    globalConfig = {
      plugins = {
        # It is not registered in asdf-vm/plugins and does not appear to be actively maintained. So specify the ref here
        # https://github.com/tvon/asdf-podman/tree/974e0fbb6051aaea0a685d8b14587113dfba9173
        podman = "https://github.com/tvon/asdf-podman.git#974e0fbb6051aaea0a685d8b14587113dfba9173";
      };
    };
  };

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/micro.nix
  # https://github.com/zyedidia/micro/blob/c15abea64c20066fc0b4c328dfabd3e6ba3253a0/runtime/help/options.md
  programs.micro = {
    enable = true;

    # `micro -options` shows candidates and we can temporally change some options by giving "-OPTION_NAME VALUE"
    settings = {
      autosu = true;
      cursorline = true;
      backup = true;
      autosave = 0; # Means false
      basename = false;
      clipboard = "external";
      colorcolumn = 0; # Means false
      diffgutter = true;
      ignorecase = true;
      incsearch = true;
      hlsearch = true;
      infobar = true;
      keepautoindent = false;
      mouse = true;
      mkparents = false;
      matchbrace = true;
      multiopen = "tab";
      reload = "prompt";
      rmtrailingws = false;
      relativeruler = false;
      savecursor = true;
      savehistory = true;
      saveundo = true;
      softwrap = true;
      splitbottom = true;
      splitright = true;
      statusline = true;
      syntax = true;
      "ft:ruby" = {
        tabsize = 2;
      };

      # Embed candidates are https://github.com/zyedidia/micro/tree/c15abea64c20066fc0b4c328dfabd3e6ba3253a0/runtime/colorschemes
      colorscheme = "twilight"; # "default" is NFM, prefer solarized for dark blue
    };
  };


  # https://github.com/nix-community/home-manager/blob/master/modules/programs/vim.nix
  # https://nixos.wiki/wiki/Vim
  programs.vim = {
    enable = true;
    # nix-env -f '<nixpkgs>' -qaP -A vimPlugins
    plugins = [ pkgs.vimPlugins.iceberg-vim ];

    settings = { background = "dark"; };
    extraConfig = ''
      colorscheme iceberg
      set termguicolors
    '';
  };

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/bat.nix
  programs.bat = {
    enable = true;

    config = {
      # Candidates: bat --list-themes
      theme = "Nord";
    };
  };
}
