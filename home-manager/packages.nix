{
  pkgs,
  edge-pkgs,
  homemade-pkgs,
  ...
}:

# Prefer stable pkgs as possible, if you want to use edge pkgs
#   - Keep zero or tiny config in home-manager layer
#   - Set `mod-name.package = edge-pkgs.the-one;`
(with pkgs; [
  # Use `bashInteractive`, don't `bash` - https://github.com/NixOS/nixpkgs/issues/29960, https://github.com/NixOS/nix/issues/730
  # bash
  # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
  bashInteractive
  # readline # needless and using it does not fix bash problems
  zsh
  fish
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
  netcat # `nc`
  dig # Alt and raw-data oriented nslookup. TODO: Consider another candidate: dug - https://eng-blog.iij.ad.jp/archives/27527

  git
  # gh # Don't add gh here. Only use home-manager gh module to avoid https://github.com/cli/cli/pull/5378
  ghq

  edge-pkgs.sequoia-sq # Alt `gpg` - nixos-24.05 does not backport recent versions and the older requires to rebuild. https://github.com/NixOS/nixpkgs/pull/331099
  edge-pkgs.sequoia-chameleon-gnupg
  gnupg # Also keep original GPG for now. sequoia-chameleon-gnupg does not support some crucial toolset. etc: `gpg --edit-key`, `gpgconf`

  age # Candidates: rage

  # Alt `pass` for password-store. Candidates: gopass, prs. Do not use ripasso-cursive for now. It only provides TUI, not a replacement of CLI. And currently unstable on my NixOS.
  gopass # They will respect pass comaptibility: https://github.com/gopasspw/gopass/issues/1365#issuecomment-719655627

  # Age fork of `pass`, also supports rage with $PASSAGE_AGE.
  edge-pkgs.passage # Use latest to apply https://github.com/NixOS/nixpkgs/pull/339113

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
  ripgrep # `rg`
  bat # alt cat
  mdcat # pipe friendly markdown viewer rather than glow
  hexyl # hex viewer
  dysk # alt df
  fd # alt find
  du-dust # `dust`, alt du
  procs
  btop # alt top
  bottom # `btm`, alt top
  xh # alt HTTPie
  zellij
  yazi # prefer the shell wrapper `yy`

  typos
  hyperfine
  difftastic # `difft`
  gnumake
  go-task # Installing for enabling shell completion easy
  gitleaks
  deno
  ruby_3_3
  _7zz # `7zz` - 7zip. Command is not 7zip.

  pastel

  rclone

  # How to get the installed font names
  # fontconfig by nix: `fc-list : family style`
  # darwin: system_profiler SPFontsDataType
  fontconfig # `fc-list`, `fc-cache`

  # `tldr` rust client, tealdeer is another candidate.
  tlrc

  fastfetch # active replacement of neofetch

  # Alternative candidates
  #  - deep-translator - not active - https://github.com/nidhaloff/deep-translator/issues/240
  #  - argos-translate - can be closed in offline, but not yet enough accuracy
  #  - Apertium - does not support Japanese
  translate-shell # `echo "$text" | trans en:ja`
])
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
  envs
  ir
  updeps
  bench_shells
  archive-home-files
  gredit
  preview
])
