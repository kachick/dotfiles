{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "kachick";
  home.homeDirectory = "/home/kachick";
  xdg.configHome = "/home/kachick/.config";
  xdg.cacheHome = "/home/kachick/.cache";
  xdg.stateHome = "/home/kachick/.local/state";
  xdg.dataHome = "/home/kachick/.local/share";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.packages = [
    pkgs.dprint
    pkgs.deno
    pkgs.gitleaks
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.nodejs
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
    pkgs.imagemagick
    pkgs.pngquant
    pkgs.rustup
    pkgs.crystal
    pkgs.ruby_3_1
    pkgs.zellij
    pkgs.nixpkgs-fmt
    pkgs.nil
    pkgs.cargo-make
    pkgs.asdf
  ];
}
