{ pkgs
, # If I need some edge dependencies, enable this section
  pkgsUnstable ? import
    (fetchTarball
      "https://github.com/NixOS/nixpkgs/bd645e8668ec6612439a9ee7e71f7eac4099d4f6.tar.gz")
    { }
, ...
}:



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

    git
    tig
    lazygit
    gh

    # GPG
    gnupg

    dprint
    shellcheck
    shfmt
    nixpkgs-fmt
    nil

    tree
    eza
    curl
    wget
    jq
    ripgrep
    bat
    hexyl
    duf
    fd
    du-dust
    procs
    bottom
    tig
    zellij
    alacritty
    typos
    hyperfine
    difftastic
    gnumake
    gitleaks
    deno
    actionlint
    pkgsUnstable.ruby_3_3

    # Do not specify vim and the plugins at here, it made collisions from home-manager vim module.
    # See following issues
    # - https://github.com/kachick/dotfiles/issues/280
    # - https://discourse.nixos.org/t/home-manager-neovim-collision/16963/2

    # Includes follows in each repository if needed, not in global
    # gcc
    # rustup
    # go
    # crystal
    # elmPackages.elm
    # sqlite
    # postgresql
    # cargo-make

    # If you need to build cruby from source, this section may remind the struggle
    # Often failed to build cruby even if I enabled following dependencies
    # zlib
    # libyaml
    # openssl

  ] ++ (lib.optionals stdenv.isLinux
    [
      # Fix missing locales as `locale: Cannot set LC_CTYPE to default locale`
      glibc

      # https://github.com/nix-community/home-manager/blob/a8f8f48320c64bd4e3a266a850bbfde2c6fe3a04/modules/services/ssh-agent.nix#L37
      openssh
    ]
  ) ++ (lib.optionals stdenv.isDarwin
    [
      # https://github.com/NixOS/nixpkgs/commit/3ea22dab7d906f400cc5983874dbadeb8127c662#diff-32e42fa095503d211e9c2894de26c22166cafb875d0a366701922aa23976c53fL21-L33
      iterm2

      # https://github.com/NixOS/nixpkgs/issues/240819
      pinentry_mac
    ]
  );
}
