{
  pkgs,
  ...
}:

(with pkgs; [
  # Use `bashInteractive`, don't `bash` - https://github.com/NixOS/nixpkgs/issues/29960, https://github.com/NixOS/nix/issues/730
  # bash
  # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
  bashInteractive
  # readline # needless and using it does not fix bash problems
  zsh
  unstable.nushell # Use unstable to apply https://github.com/nushell/nushell/commit/4ed25b63a6fc3444bb870dd6fa2c5a9abb936b00 # TODO: Use stable since nixos-25.05
  starship
  direnv
  unstable.nixfmt-rfc-style # Always required on Nix Life. It should be stable in all channels

  fzf # History: CTRL+R, Walker: CTRL+T
  # https://github.com/junegunn/fzf/blob/d579e335b5aa30e98a2ec046cb782bbb02bc28ad/ADVANCED.md#key-bindings-for-git-objects
  # CTRL+O does not open web browser in WSL: https://github.com/kachick/dotfiles/issues/499
  fzf-git-sh # CTRL-G CTRL-{} keybinds for git
  # Use same nixpkgs channel as same as fzf
  television # `tv`. Alt fzf
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
  dig # Alt and raw-data oriented nslookup. # Candidates: dug - https://eng-blog.iij.ad.jp/archives/27527

  git
  # gh # Don't add gh here. Only use home-manager gh module to avoid https://github.com/cli/cli/pull/5378
  ghq

  sequoia-sq # Alt `gpg`
  sequoia-chameleon-gnupg
  gnupg # Also keep original GPG for now. sequoia-chameleon-gnupg does not support some crucial toolset. etc: `gpg --edit-key`, `gpgconf`

  age # Candidates: rage

  # Alt `pass` for password-store. Candidates: gopass, prs. Do not use ripasso-cursive for now. It only provides TUI, not a replacement of CLI. And currently unstable on my NixOS.
  unstable.gopass # Use unstable to apply https://github.com/NixOS/nixpkgs/pull/360950

  # Age fork of `pass`, also supports rage with $PASSAGE_AGE.
  passage

  # Do not specify vim and the plugins at here, it made collisions from home-manager vim module.
  # See following issues
  # - https://github.com/kachick/dotfiles/issues/280
  # - https://discourse.nixos.org/t/home-manager-neovim-collision/16963/2

  micro
  unstable.ox # modeless editor.

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
  bottom # `btm`, alt top
  xh # alt HTTPie
  zellij
  unstable.sad # Require 0.4.32 or later to use fzf's `become` # TODO: Prefer stable since nixos-25.05

  typos
  hyperfine
  riffdiff # `riff`
  gnumake
  unstable.gitleaks
  ruby_3_4
  _7zz # `7zz` - 7zip. Command is not 7zip.

  pastel

  # How to get the installed font names
  # fontconfig by nix: `fc-list : family style`
  # darwin: system_profiler SPFontsDataType
  fontconfig # `fc-list`, `fc-cache`

  # `tldr` rust client, tealdeer is another candidate.
  tlrc

  fastfetch # active replacement of neofetch
])
++ (with pkgs.unstable; [
  gurk-rs # Require https://github.com/NixOS/nixpkgs/pull/356353 to link
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
  updeps
  bench_shells
  preview
])
