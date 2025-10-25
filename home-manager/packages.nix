{ pkgs, ... }:

(with pkgs; [
  # Use `bashInteractive`, don't `bash` - https://github.com/NixOS/nixpkgs/issues/29960, https://github.com/NixOS/nix/issues/730
  # bash
  # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
  bashInteractive
  # readline # needless and using it does not fix bash problems
  zsh
  starship
  direnv
  unstable.nixfmt
  nushell
  atuin

  fzf # History: CTRL+R, Walker: CTRL+T
  # fzf-git-sh for CTRL-G CTRL-{} keybinds should be manually integrated in each shell
  # Use same nixpkgs channel as same as fzf
  television # `tv`. Alt fzf
  unstable.zoxide # Used in alias `z`, alt cd/pushd. popd = `z -`, fzf-mode = `zi`

  # Used in anywhere
  coreutils
  less # container base image doesn't have less even for ubuntu official
  procps # `ps`

  # Use same tools even in macOS
  findutils
  diffutils
  gnugrep
  netcat # `nc`
  dig # Alt and raw-data oriented nslookup. # Candidates: dug - https://eng-blog.iij.ad.jp/archives/27527

  git
  # gh # Don't add gh here. Only use home-manager gh module to avoid https://github.com/cli/cli/pull/5378
  ghq

  sequoia-sq # Alt `gpg`
  sequoia-chameleon-gnupg
  gnupg # Also keep original GPG for now. sequoia-chameleon-gnupg does not support some crucial toolset. etc: `gpg --edit-key`, `gpgconf`

  age # Candidates: rage

  # Alt `pass` for password-store. Candidates: gopass, prs. Do not use ripasso-cursive for now. It only provides TUI, not a replacement of CLI. And currently unstable on my NixOS.
  gopass

  # Age fork of `pass`, also supports rage with $PASSAGE_AGE.
  passage

  # Do not specify vim and the plugins at here, it made collisions from home-manager vim module.
  # See following issues
  # - https://github.com/kachick/dotfiles/issues/280
  # - https://discourse.nixos.org/t/home-manager-neovim-collision/16963/2

  # TODO: Prefer stable channel since nixos-25.11
  # Available since https://github.com/NixOS/nixpkgs/pull/409075
  # Fixed in https://github.com/NixOS/nixpkgs/pull/449790 for x86_64-darwin
  unstable.msedit # `edit`

  micro

  tree
  eza # alt ls
  curl
  wget
  jq
  ripgrep # `rg`
  bat # alt cat
  mdcat # pipe friendly markdown viewer rather than glow
  hexyl # hex viewer
  fd # alt find
  du-dust # `dust`, alt du
  my.bottom # `btm`, alt top
  xh # alt HTTPie
  zellij
  sad

  typos
  hyperfine
  riffdiff # `riff`
  gnumake
  unstable.gitleaks
  ruby_3_4
  _7zz # `7zz` - 7zip. Command is not 7zip.

  # Keybindigs: https://git.sr.ht/~bptato/chawan/tree/master/item/res/config.toml
  chawan # `cha`

  yazi

  pastel

  # How to get the installed font names
  # fontconfig by nix: `fc-list : family style`
  # darwin: system_profiler SPFontsDataType
  fontconfig # `fc-list`, `fc-cache`

  # `tldr` rust client, tealdeer is another candidate.
  tlrc

  fastfetch # active replacement of neofetch

  # Require unstable version because
  #   - Stable binary cache: https://github.com/reubeno/brush/pull/600
  #   - $BRUSH_VERSION for gradual adoption: https://github.com/reubeno/brush/pull/531
  unstable.brush

  # Available since https://github.com/NixOS/nixpkgs/pull/423741
  patched.somo

  # Available since https://github.com/NixOS/nixpkgs/pull/410902
  unstable.typescript-go
])
++ (with pkgs.my; [
  la
  lat
  fzf-bind-posix-shell-history-to-git-commit-message
  git-delete-merged-branches
  todo
  ghqf
  p
  walk
  rg-fzf
  envs
  ir
  bench_shells
  preview
  renmark
  tree-diff
  gurk-rs-bin
])
