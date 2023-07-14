{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "kachick";
  # TODO: How to cover lima? The default is /home/kachick.local
  home.homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";
  xdg.configHome = "${config.home.homeDirectory}/.config";
  xdg.cacheHome = "${config.home.homeDirectory}/.cache";
  xdg.stateHome = "${config.home.homeDirectory}/.local/state";
  xdg.dataHome = "${config.home.homeDirectory}/.local/share";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # TODO: Consider to manage nix.conf with home-manager. However it includes`trusted-public-keys`
  # nix.package = pkgs.nix;
  # nix.settings = {
  #   experimental-features = "nix-command";
  # };
  # nix.extraOptions = ''
  #   experimental-features = nix-command
  # '';

  home.packages = [
    pkgs.dprint
    pkgs.deno
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
    pkgs.rustup
    pkgs.crystal
    pkgs.zellij
    pkgs.nixpkgs-fmt
    pkgs.nil
    pkgs.typos
    pkgs.cargo-make
    pkgs.hyperfine
    pkgs.zoxide
    pkgs.helix
    pkgs.delta
    pkgs.gnumake
    pkgs.elmPackages.elm

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
