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

    # asdf/rtx
    #
    # Using rtx now
    # pkgs.asdf-vm
    pkgs.rtx
    #
    # Required in many asdf plugins
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
