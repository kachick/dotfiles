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
    # Use `bashInteractive`, don't `bash` - https://github.com/NixOS/nixpkgs/issues/29960, https://github.com/NixOS/nix/issues/730
    # pkgs.bash
    # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
    pkgs.bashInteractive
    # pkgs.readline # needless and using it does not fix pkgs.bash problems
    pkgs.zsh
    pkgs.fish
    pkgs.starship
    pkgs.direnv
    pkgs.zoxide
    pkgs.fzf

    # asdf/rtx
    #
    # Prefer rtx now
    # pkgs.asdf-vm
    pkgs.rtx
    #
    # Required in many asdf plugins
    pkgs.unzip

    pkgs.git
    pkgs.tig
    pkgs.gh

    pkgs.dprint
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.nixpkgs-fmt

    pkgs.coreutils
    pkgs.tree
    pkgs.exa
    pkgs.curl
    pkgs.wget
    pkgs.jq
    pkgs.ripgrep
    pkgs.bat
    pkgs.duf
    pkgs.fd
    pkgs.du-dust
    pkgs.procs
    pkgs.bottom
    pkgs.tig
    pkgs.zellij
    pkgs.typos
    pkgs.hyperfine
    pkgs.difftastic

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
    # pkgs.gitleaks
    # pkgs.nil

    # https://github.com/NixOS/nixpkgs/pull/218114
    pkgs.ruby_3_2
    # If you need to build cruby from source, this section may remind the struggle
    # Often failed to build cruby even if I enabled following dependencies
    # pkgs.zlib
    # pkgs.libyaml
    # pkgs.openssl

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
