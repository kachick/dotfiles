{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "kachick";
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

  programs.fish = {
    enable = true;

    shellInit =
      ''
        switch (uname -s)
        case Linux
            # Keep this comment
        case Darwin
          # nix
          # https://github.com/NixOS/nix/issues/2280
          if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
            fenv source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
          end
        case FreeBSD NetBSD DragonFly
            # Keep this comment
        case '*'
            # Keep this comment
        end

        # nix
        if test -e "$HOME/.nix-profile/etc/profile.d/nix.sh"
            fenv source "$HOME/.nix-profile/etc/profile.d/nix.sh"
        end

        # home-manager
        if test -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
            fenv source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
        end

        # starship
        if status is-interactive
            starship init fish | source
        end
      '';

    shellAliases = {
      la = "exa --long --all --group-directories-first";
    };

    plugins = [{
      name = "foreign-env";
      src = pkgs.fetchFromGitHub {
        owner = "oh-my-fish";
        repo = "plugin-foreign-env";
        rev = "3ee95536106c11073d6ff466c1681cde31001383";
        sha256 = "sha256-vyW/X2lLjsieMpP9Wi2bZPjReaZBkqUbkh15zOi8T4Y=";
      };
    }];
  };

  programs.readline = {
    enable = true;
    variables = {
      # https://unix.stackexchange.com/questions/73672/how-to-turn-off-the-beep-only-in-bash-tab-complete
      # https://github.com/nix-community/home-manager/blob/0841242b94638fcd010f7f64e56b7b1cad50c697/modules/programs/readline.nix
      bell-style = "none";
    };
  };

  programs.direnv.enable = true;

  programs.zoxide.enable = true;

  # https://nixos.wiki/wiki/Home_Manager
  #   - Prefer XDG_*
  #   - If can't write the reason as a comment

  xdg.configFile."home-manager/home.nix".source = ./home.nix;
  xdg.configFile."git/config".source = ../git/config;
  xdg.configFile."zsh/.zshrc".source = ../zsh/.zshrc;
  xdg.configFile."zsh/.zprofile".source = ../zsh/.zprofile;
  xdg.configFile."fish/fish_variables".source = ../fish/fish_variables;
  xdg.configFile."fish/functions/fish_prompt.fish".source = ../fish/functions/fish_prompt.fish;
  xdg.configFile."irb/irbrc".source = ../irb/irbrc;
  xdg.configFile."alacritty/alacritty.yml".source = ../alacritty/alacritty.yml;
  xdg.configFile."nushell/config.nu".source = ../nushell/config.nu;
  xdg.configFile."nushell/env.nu".source = ../nushell/env.nu;
  xdg.configFile."sheldon/plugins.toml".source = ../sheldon/plugins.toml;

  # Not under "starship/starship.toml"
  xdg.configFile."starship.toml".source = ../starship.toml;

  # I call "homemade" for own created tools
  xdg.configFile."homemade/.aliases.sh".source = ../homemade/.aliases.sh;

  # basic shell dotfiles should be put in ~/ except part of zsh files
  home.file.".bashrc".source = ../../home/.bashrc;
  home.file.".bash_logout".source = ../../home/.bash_logout;
  home.file.".zshenv".source = ../../home/.zshenv;

  # - stack manager can not found in https://github.com/nix-community/home-manager/tree/8d243f7da13d6ee32f722a3f1afeced150b6d4da/modules/programs
  # - https://github.com/kachick/dotfiles/issues/142
  home.file.".stack/config.yaml".source = ../../home/.stack/config.yaml;

  # https://github.com/rbenv/rbenv-default-gems/issues/17
  home.file.".default-gems".text = ''
    irb-power_assert
  '';

  home.packages = [
    pkgs.dprint
    pkgs.deno
    # pkgs.rustup
    pkgs.go
    # pkgs.crystal
    pkgs.elmPackages.elm
    pkgs.gitleaks
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.gcc
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
    pkgs.sqlite
    pkgs.postgresql
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
    pkgs.tesseract
    pkgs.tig
    pkgs.zellij
    pkgs.nixpkgs-fmt
    pkgs.nil
    pkgs.typos
    pkgs.cargo-make
    pkgs.hyperfine
    pkgs.zoxide
    pkgs.difftastic
    pkgs.gnumake

    # Do not manage sheldon with nix for unsupported Darwin https://github.com/kachick/dotfiles/issues/149
    # pkgs.sheldon

    # Required in many asdf(rtx) plugins
    pkgs.unzip

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
    pkgs.imagemagick
    pkgs.pngquant
    pkgs.img2pdf
    pkgs.ocrmypdf
  ];
}

