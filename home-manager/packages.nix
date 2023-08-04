{ pkgs, ... }:

# If I need the some of edge dependencies, this is the how to point unstable
#
# let
#   pkgsUnstable = import
#     (fetchTarball
#       "https://releases.nixos.org/nixpkgs/nixpkgs-23.11pre509044.3acb5c4264c4/nixexprs.tar.xz")
#     { };
# in

{
  home.packages = with pkgs; [
    # Use `bashInteractive`, don't `bash` - https://github.com/NixOS/nixpkgs/issues/29960, https://github.com/NixOS/nix/issues/730
    # bash
    # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
    bashInteractive
    # readline # needless and using it does not fix bash problems
    zsh
    fish
    starship
    direnv
    zoxide
    fzf

    # Used in anywhere
    coreutils

    # asdf/rtx
    #
    # Prefer rtx now
    # asdf-vm
    rtx
    #
    # Required in many asdf plugins
    unzip

    git
    tig
    lazygit
    gh

    dprint
    shellcheck
    shfmt
    nixpkgs-fmt

    tree
    exa
    curl
    wget
    jq
    ripgrep
    bat
    duf
    fd
    du-dust
    procs
    bottom
    tig
    zellij
    typos
    hyperfine
    difftastic

    # Includes follows in each repository if needed, not in global
    # deno
    # rustup
    # go
    # crystal
    # elmPackages.elm
    # gcc
    # sqlite
    # postgresql
    # gnumake
    # cargo-make
    # gitleaks
    # nil

    # https://github.com/NixOS/nixpkgs/pull/218114
    ruby_3_2
    # If you need to build cruby from source, this section may remind the struggle
    # Often failed to build cruby even if I enabled following dependencies
    # zlib
    # libyaml
    # openssl

    # As a boardgamer
    # tesseract
    # imagemagick
    # pngquant
    # img2pdf
    # ocrmypdf
  ] ++ (
    if stdenv.isDarwin then
      [ ]
    else
      [
        # Fix missing locales as `locale: Cannot set LC_CTYPE to default locale`
        glibc
      ]
  );
}
