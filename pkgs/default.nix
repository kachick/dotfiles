{ pkgs, edge-pkgs, ... }:

{
  bump_completions = import ./bump_completions { inherit pkgs edge-pkgs; };

  bump_gomod = import ./bump_gomod { inherit pkgs; };

  check_no_dirty_xz_in_nix_store = import ./check_no_dirty_xz_in_nix_store { inherit pkgs; };
  check_nixf = import ./check_nixf { inherit pkgs edge-pkgs; };

  safe_quote_backtik = import ./safe_quote_backtik { inherit pkgs; };

  bench_shells = import ./bench_shells { inherit pkgs; };

  updeps = import ./updeps { inherit pkgs; };

  la = import ./la { inherit pkgs; };

  lat = import ./lat { inherit pkgs; };

  zed = import ./zed { inherit pkgs edge-pkgs; };

  walk = import ./walk { inherit pkgs; };

  ir = pkgs.callPackage ./ir { };

  zj = import ./zj { inherit pkgs; };

  p = import ./p { inherit pkgs; };

  g = import ./g { inherit pkgs; };

  git-delete-merged-branches = import ./git-delete-merged-branches { inherit pkgs; };

  fzf-bind-posix-shell-history-to-git-commit-message =
    import ./fzf-bind-posix-shell-history-to-git-commit-message
      { inherit pkgs; };

  todo = import ./todo { inherit pkgs; };

  ghqf = import ./ghqf { inherit pkgs; };

  archive-home-files = import ./archive-home-files { inherit pkgs; };

  git-log-fzf = import ./git-log-fzf { inherit pkgs; };
  git-log-simple = import ./git-log-simple { inherit pkgs; };

  git-hooks-commit-msg = import ./git-hooks-commit-msg { inherit pkgs; };
  git-hooks-pre-push = import ./git-hooks-pre-push { inherit pkgs; };

  gh-prs = import ./gh-prs { inherit pkgs; };

  envs = import ./envs { inherit pkgs; };

  reponame = import ./reponame { inherit pkgs; };

  beedii = pkgs.callPackage ./beedii { };
  cozette = pkgs.callPackage ./cozette { };
  maccy = pkgs.callPackage ./maccy { };

  posix_shared_functions = pkgs.callPackage ./posix_shared_functions { };

  micro-fzfinder = pkgs.callPackage ./micro-fzfinder { };
  micro-kdl = pkgs.callPackage ./micro-kdl { };
  micro-nordcolors = pkgs.callPackage ./micro-nordcolors { };
  micro-everforest = pkgs.callPackage ./micro-everforest { };
  micro-catppuccin = pkgs.callPackage ./micro-catppuccin { };

  nix-hash-url = pkgs.callPackage ./nix-hash-url { };

  gredit = pkgs.callPackage ./gredit { };
  git-resolve-conflict = pkgs.callPackage ./git-resolve-conflict { };
  renmark = pkgs.callPackage ./renmark { };
  preview = pkgs.callPackage ./preview { };
}
