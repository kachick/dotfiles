{
  pkgs,
  edge-pkgs,
  homemade-pkgs,
  ...
}:

# Prefer stable pkgs as possible, if you want to use edge pkgs
#   - Keep zero or tiny config in home-manager layer
#   - Set `mod-name.package = edge-pkgs.the-one;`
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

  fzf # History: CTRL+R, Walker: CTRL+T
  # https://github.com/junegunn/fzf/blob/d579e335b5aa30e98a2ec046cb782bbb02bc28ad/ADVANCED.md#key-bindings-for-git-objects
  # CTRL+O does not open web browser in WSL: https://github.com/kachick/dotfiles/issues/499
  fzf-git-sh # CTRL-G CTRL-{} keybinds for git
  # Use same nixpkgs channel as same as fzf
  zoxide # Used in alias `z`, alt cd/pushd. popd = `z -`, fzf-mode = `zi`

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
  edge-pkgs.jnv # interactive jq - Use unstable because it is a fresh tool
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

  # Do not install wezterm in home-manager layer for non NixOS
  # - Released wezterm versions are broken on wayland
  # - Using nightly needs to take long build time, avoiding it for CI time
  alacritty

  typos
  hyperfine
  difftastic # `difft`
  gnumake
  gitleaks
  edge-pkgs.deno # Use unstable to track latest
  ruby_3_3
  unzip # Required in many asdf plugins
  _7zz # `7zz` 7zip, not

  pastel

  rclone

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
  plemoljp-nf
  ibm-plex # For sans-serif, use plemoljp for developing

  source-han-code-jp # Includes many definitions, useful for fallback
  inconsolata

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

  # - Enable special module for Nix OS.
  # - Linux package does not contain podman-remote, you should install uidmap with apt and use this podman as actual engine
  #   https://github.com/NixOS/nixpkgs/blob/194846768975b7ad2c4988bdb82572c00222c0d7/pkgs/applications/virtualization/podman/default.nix#L112-L116
  # - In darwin, this package will be used for podman-remote, you should manually install podman-desktop for the engine
  podman
  podman-tui
  docker-compose

  fastfetch # active replacement of neofetch
]
++ (with homemade-pkgs; [
  la
  lat
  fzf-bind-posix-shell-history-to-git-commit-message
  git-delete-merged-branches
  todo
  ghqf
  zj
  p
  g
  walk
  updeps
  bench_shells
  archive-home-files
  prs
])
++ (lib.optionals stdenv.isLinux [
  # Fix missing locales as `locale: Cannot set LC_CTYPE to default locale`
  glibc

  # https://github.com/nix-community/home-manager/blob/a8f8f48320c64bd4e3a266a850bbfde2c6fe3a04/modules/services/ssh-agent.nix#L37
  openssh

  iputils # `ping` etc

  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/iw/iw/package.nix
  edge-pkgs.iw # replacement of wireless-tools(iwconfig)

  # `tldr` rust client, tealdeer is another candidate.
  # Do not inject this tlrc package in macOS, it is broken even in stable NixOS channel. See GH-720
  tlrc
])
++ (lib.optionals stdenv.isDarwin [
  # https://github.com/NixOS/nixpkgs/issues/240819
  pinentry_mac
])
