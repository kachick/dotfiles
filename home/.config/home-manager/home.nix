{ config, pkgs, lib, ... }:

# FAQ
#   - How to get sha256? => assume by `lib.fakeSha256`

{
  imports = [
    ./packages.nix
    ./zsh.nix
    ./fish.nix
    ./nushell.nix
  ];

  home.username = lib.mkDefault "kachick";
  # TODO: How to cover lima? The default is /home/kachick.local
  home.homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";

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
  home.stateVersion = "23.05";

  home = {
    sessionVariables = {
      INPUTRC = "${config.home.sessionVariables.XDG_CONFIG_HOME}/readline/inputrc";
      EDITOR = "code -w";
      VISUAL = "nano";
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
      "${config.xdg.dataHome}/homemade/bin"
    ];
  };

  # This also changes xdg? Official manual sed this config is better for non NixOS Linux
  # https://github.com/nix-community/home-manager/blob/559856748982588a9eda6bfb668450ebcf006ccd/modules/targets/generic-linux.nix#L16
  targets.genericLinux.enable = if pkgs.stdenv.hostPlatform.isDarwin then false else true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  nix = {
    enable = true;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };

    # Without this makes following errors
    #
    #  error:
    #  Failed assertions:
    #  - A corresponding Nix package must be specified via `nix.package` for generating
    package = pkgs.nix;
  };

  programs.readline = {
    enable = true;
    variables = {
      # https://unix.stackexchange.com/questions/73672/how-to-turn-off-the-beep-only-in-bash-tab-complete
      # https://github.com/nix-community/home-manager/blob/0841242b94638fcd010f7f64e56b7b1cad50c697/modules/programs/readline.nix
      bell-style = "none";
    };
  };

  programs.lesspipe.enable = true;

  programs.direnv = {
    enable = true;

    # Replacement of `programs.direnv.enableNixDirenvIntegration = true;`
    nix-direnv = {
      enable = true;
    };

    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  # https://nixos.wiki/wiki/Home_Manager
  #   - Prefer XDG_*
  #   - If can't write the reason as a comment

  xdg.configFile."home-manager/home.nix".source = ./home.nix;
  xdg.configFile."git/config".source = ../git/config;
  xdg.configFile."fish/fish_variables".source = ../fish/fish_variables;
  xdg.configFile."fish/functions/fish_prompt.fish".source = ../fish/functions/fish_prompt.fish;
  xdg.configFile."alacritty/alacritty.yml".source = ../alacritty/alacritty.yml;

  # Not under "starship/starship.toml"
  xdg.configFile."starship.toml".source = ../starship.toml;

  # basic shell dotfiles should be put in ~/ except part of zsh files
  home.file.".bashrc".source = ../../../home/.bashrc;
  home.file.".bash_logout".source = ../../../home/.bash_logout;

  # - stack manager can not found in https://github.com/nix-community/home-manager/tree/8d243f7da13d6ee32f722a3f1afeced150b6d4da/modules/programs
  # - https://github.com/kachick/dotfiles/issues/142
  home.file.".stack/config.yaml".source = ../../../home/.stack/config.yaml;

  # Should have `root = true` in the file. - https://github.com/kachick/anylang-template/blob/45d7ef685ac4fd3836c3b32b8ce8fb45e909b771/.editorconfig#L1
  # Intentionally avoided to use https://github.com/nix-community/home-manager/blob/f58889c07efa8e1328fdf93dc1796ec2a5c47f38/modules/misc/editorconfig.nix
  home.file.".editorconfig".text = builtins.readFile (
    pkgs.fetchFromGitHub
      {
        owner = "kachick";
        repo = "anylang-template";
        rev = "45d7ef685ac4fd3836c3b32b8ce8fb45e909b771";
        sha256 = "sha256-F8xP4xCIS1ybvRm1xGB2USekGWKKxz0nokpY6gRxKBE=";
      }
    + "/.editorconfig"
  );

  xdg.configFile."irb/irbrc".text = builtins.readFile (
    pkgs.fetchFromGitHub
      {
        owner = "kachick";
        repo = "irb-power_assert";
        rev = "98ad68b4c391bb30adee1ba119cb6c6ed5bd0bfc";
        sha256 = "sha256-Su3jaPELaBKa+CJpNp6OzOb/6/wwGk7JDxP/w9wVBtM=";
      }
    + "/examples/.irbrc"
  );

  # https://github.com/rbenv/rbenv-default-gems/issues/17
  home.file.".default-gems".text = ''
    irb-power_assert
  '';

  programs.fzf = {
    enable = true;

    # enableShellIntegration = true;

    enableZshIntegration = true;

    # enableFishIntegration  = true;

    # fzf manager does not have nushell integration yet.
    # https://github.com/nushell/nushell/issues/1616#issuecomment-1386714173 may help you.
  };

  programs.starship = {
    enable = true;

    # enableShellIntegration = true;
    enableZshIntegration = true;
    # enableFishIntegration = true;
    enableNushellIntegration = true;
  };

  # - Tiny tools by me, they may be rewritten with another language.
  # - Keep *.bash in shellscript naming in this repo for maintainability, the extname should be trimmed in the symlinks
  xdg.dataFile."homemade/bin/bench_shells".source = ../../../home/.local/share/homemade/bin/bench_shells.bash;
  xdg.dataFile."homemade/bin/updeps".source = ../../../home/.local/share/homemade/bin/updeps.bash;
  xdg.dataFile."homemade/bin/la".source = ../../../home/.local/share/homemade/bin/la.bash;
  xdg.dataFile."homemade/bin/zj".source = ../../../home/.local/share/homemade/bin/zj.bash;

  home.packages = [
    pkgs.dprint
    pkgs.gitleaks
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.git
    pkgs.coreutils
    pkgs.tig
    pkgs.tree
    pkgs.curl
    pkgs.wget
    pkgs.zsh
    # Don't include bash - https://github.com/NixOS/nixpkgs/issues/29960, https://github.com/NixOS/nix/issues/730
    # pkgs.bash
    pkgs.fish
    pkgs.nushell
    pkgs.starship
    pkgs.jq
    pkgs.gh
    pkgs.direnv
    pkgs.ripgrep
    pkgs.fzf
    pkgs.exa
    pkgs.bat
    pkgs.duf
    pkgs.fd
    pkgs.du-dust
    pkgs.procs
    pkgs.bottom
    pkgs.tig
    pkgs.zellij
    pkgs.nixpkgs-fmt
    pkgs.nil
    pkgs.typos
    pkgs.hyperfine
    pkgs.zoxide
    pkgs.difftastic

    # Required in many asdf(rtx) plugins
    pkgs.unzip

    # Includes follows in each repository if needed, not in global
    # pkgs.deno
    # pkgs.rustup
    # pkgs.go
    # pkgs.crystal
    # pkgs.elmPackages.elm
    # pkgs.gcc
    # pkgs.sqlite
    # pkgs.postgresql
    # pkgs.gnumake
    # pkgs.cargo-make

    # This section is just a note for my strggle
    # Often failed to build ruby even if I enabled following dependencies
    # pkgs.zlib
    # pkgs.libyaml
    # pkgs.openssl
    #
    # Don't include nixpkgs ruby, because of installing into .nix-profile hides
    # adhoc use of https://github.com/bobvanderlinden/nixpkgs-ruby
    # pkgs.ruby

    # As a boardgamer
    # pkgs.tesseract
    # pkgs.imagemagick
    # pkgs.pngquant
    # pkgs.img2pdf
    # pkgs.ocrmypdf
  ] ++ (
    if pkgs.stdenv.hostPlatform.isDarwin then
      [ ]
    else
      [
        # Fix missing locales as `locale: Cannot set LC_CTYPE to default locale`
        pkgs.glibc
      ]
  );
}
