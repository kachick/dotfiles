{ pkgs, ... }:

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

    # Use same tools even in macOS
    findutils
    diffutils
    gnugrep
    gnused
    gawk

    # asdf/rtx
    #
    # Prefer rtx now
    # asdf-vm
    rtx
    #
    # Required in many asdf plugins
    unzip

    # In macOS, starting ssh-agent is still /usr/bin/ssh-agent even added the nixpkgs
    # So avoiding to add it for now
    # openssh

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
  ] ++ (lib.optionals stdenv.isLinux
    [
      # Fix missing locales as `locale: Cannot set LC_CTYPE to default locale`
      glibc
    ]
  ) ++ (lib.optionals stdenv.isDarwin
    [
      # https://github.com/NixOS/nixpkgs/commit/3ea22dab7d906f400cc5983874dbadeb8127c662#diff-32e42fa095503d211e9c2894de26c22166cafb875d0a366701922aa23976c53fL21-L33
      iterm2
    ]
  );
}
