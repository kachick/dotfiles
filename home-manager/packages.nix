{
  pkgs,
  edge-pkgs,
  lib,
  ...
}:

{
  # Prefer stable pkgs as possible, if you want to use edge pkgs
  #   - Keep zero or tiny config in home-manager layer
  #   - Set `mod-name.package = edge-pkgs.the-one;`
  home.packages =
    with pkgs;
    [
      # Use `bashInteractive`, don't `bash` - https://github.com/NixOS/nixpkgs/issues/29960, https://github.com/NixOS/nix/issues/730
      # bash
      # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
      bashInteractive
      # readline # needless and using it does not fix bash problems
      zsh
      fish
      powershell # Keep to stable nixpkgs, because this is one of the depending to xz. See #530
      starship
      direnv
      zoxide # Used in alias `z`, alt cd/pushd. popd = `z -`, fzf-mode = `zi`

      # Using in stable home-manager integration, but using edge fzf here.
      # Because strongly want to use the new features. Consider to translate Nix -> native config style
      edge-pkgs.fzf # History: CTRL+R, Walker: CTRL+T
      # https://github.com/junegunn/fzf/blob/d579e335b5aa30e98a2ec046cb782bbb02bc28ad/ADVANCED.md#key-bindings-for-git-objects
      # CTRL+O does not open web browser in WSL: https://github.com/kachick/dotfiles/issues/499
      edge-pkgs.fzf-git-sh # CTRL-G CTRL-{} keybinds for git

      # Used in anywhere
      coreutils
      less # container base image doesn't have less even for ubuntu official
      procps # `ps`

      # Use same tools even in macOS
      findutils
      diffutils
      gnugrep
      gnused
      gawk
      netcat # `nc`

      edge-pkgs.mise # alt asdf

      git
      gh
      ghq

      # GPG
      gnupg

      # Do not specify vim and the plugins at here, it made collisions from home-manager vim module.
      # See following issues
      # - https://github.com/kachick/dotfiles/issues/280
      # - https://discourse.nixos.org/t/home-manager-neovim-collision/16963/2

      micro # alt nano

      tree
      eza # alt ls
      curl
      wget
      jq
      edge-pkgs.jnv # interactive jq
      ripgrep # `rg`
      bat # alt cat
      hexyl # hex viewer
      dysk # alt df
      fd # alt find
      du-dust # `dust`, alt du
      procs
      bottom # `btm`, alt top
      xh # alt HTTPie
      zellij
      edge-pkgs.alacritty
      edge-pkgs.typos
      hyperfine
      difftastic
      gnumake
      gitleaks
      edge-pkgs.deno
      edge-pkgs.ruby_3_3
      unzip # Required in many asdf plugins
      _7zz # `7zz` 7zip, not
      tlrc # `tldr` rust client, tealdeer is another candidate

      # How to get the installed font names
      # fontconfig by nix: `fc-list : family style`
      # darwin: system_profiler SPFontsDataType
      fontconfig # `fc-list`, `fc-cache`

      # - You can use major Nerd Fonts as `pkgs.nerdfonts.override ...`
      # - Should have at least 1 composite font that includes Monospace + Japanese + Nerd fonts,
      #   because of alacritty does not have the fallback font feature. https://github.com/alacritty/alacritty/issues/957
      # - Keep fewer nerd fonts to reduce disk space

      # You can also use 0 = `Slashed zero style` with enabling `"editor.fontLigatures": "'zero'"` in vscode
      # but cannot use it in alacritty https://github.com/alacritty/alacritty/issues/50
      edge-pkgs.plemoljp-nf
      pkgs.ibm-plex # For sans-serif, use plemoljp for developing

      pkgs.source-han-code-jp # Includes many definitions, useful for fallback
      pkgs.inconsolata
      pkgs.mplus-outline-fonts.githubRelease # https://github.com/NixOS/nixpkgs/blob/c56f470377573b3170b62242ce21abcc196cb4ef/pkgs/data/fonts/mplus-outline-fonts/default.nix#L33
      # pkgs.sarasa-gothic # Large filesize

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
    ]
    ++ (import ./homemade.nix {
      inherit pkgs;
      inherit edge-pkgs;
    })
    ++ (lib.optionals stdenv.isLinux [
      # Fix missing locales as `locale: Cannot set LC_CTYPE to default locale`
      glibc

      # https://github.com/nix-community/home-manager/blob/a8f8f48320c64bd4e3a266a850bbfde2c6fe3a04/modules/services/ssh-agent.nix#L37
      openssh

      iputils # `ping` etc

      wslu # WSL helpers like `wslview`
    ])
    ++ (lib.optionals stdenv.isDarwin [
      # https://github.com/NixOS/nixpkgs/issues/240819
      pinentry_mac
    ]);
}
