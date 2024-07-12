{ pkgs, ... }:

{
  bump_completions = import ./bump_completions { inherit pkgs; };

  bump_gomod = import ./bump_gomod { inherit pkgs; };

  check_no_dirty_xz_in_nix_store = import ./check_no_dirty_xz_in_nix_store { inherit pkgs; };

  safe_quote_backtik = import ./safe_quote_backtik { inherit pkgs; };

  bench_shells = import ./bench_shells { inherit pkgs; };

  updeps = import ./updeps { inherit pkgs; };

  la = import ./la { inherit pkgs; };

  lat = import ./lat { inherit pkgs; };

  walk = import ./walk { inherit pkgs; };

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

  prs = import ./prs { inherit pkgs; };

  trim-github-user-prefix-for-reponame = import ./trim-github-user-prefix-for-reponame {
    inherit pkgs;
  };

  beedii = import ./beedii { inherit pkgs; };
}
