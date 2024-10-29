{ lib, pkgs, ... }:
# https://unix.stackexchange.com/a/3449
# Use shared aliases in both bash and zsh with sourcing
#
# - We CAN use `local` and `local -r` if omit ksh
# - Keep minimum
# - aliases around `cd` is the typical use, because they should be alias or sourced shell function
# - Prefer `fname() {}` style: https://unix.stackexchange.com/a/73854
# - Do not add shebang and options. It means you shouldn't select `writeShellApplication` here
#
# NOTE: You should remember difference of bash and zsh for the arguments handling in completions
# https://rcmdnk.com/blog/2015/05/15/computer-linux-mac-zsh/
#
# How to stop blinking cursor in Linux console?
# => https://web-archive-org.translate.goog/web/20220318101402/https://nutr1t07.github.io/post/disable-cursor-blinking-on-linux-console/?_x_tr_sl=auto&_x_tr_tl=ja&_x_tr_hl=ja
let
  reponame = pkgs.callPackage ../reponame { };
  ghqf = pkgs.callPackage ../ghqf { };
  fzf-bind-posix-shell-history-to-git-commit-message =
    pkgs.callPackage ../fzf-bind-posix-shell-history-to-git-commit-message
      { };
in
pkgs.writeText "posix_shared_functions.sh" (
  ''
    cdrepo() {
      local -r query_repoonly="$(echo "$1" | ${lib.getExe reponame})"
      local -r repo="$(${lib.getExe ghqf} "$query_repoonly")"
      if [ -n "$repo" ]; then
        cd "$(${lib.getExe pkgs.ghq} list --full-path --exact "$repo")"
      fi
    }

    getrepo() {
      ${lib.getExe pkgs.ghq} get "$1" && cdrepo "$1"
    }

    cdtemp() {
      cd "$(${pkgs.coreutils}/bin/mktemp --directory)"
    }

    cdnix() {
      if [ $# -lt 1 ]; then
        echo "Specify Nix injected command you want to dive"
        return 2
      fi
      # TODO: Check exit code and Nix or not
      local -r command="$(command -v "$1")"
      # shellcheck disable=SC2164
      cd "$(${pkgs.coreutils}/bin/dirname "$(${pkgs.coreutils}/bin/dirname "$(${pkgs.coreutils}/bin/readlink --canonicalize "$command")")")"
    }

    gch() {
      fc -nrl 1 | ${lib.getExe fzf-bind-posix-shell-history-to-git-commit-message}
    }

    y() {
      local tmp="$(${pkgs.coreutils}/bin/mktemp -t "yazi-cwd.XXXXXX")"
      ${lib.getExe pkgs.yazi} "$@" --cwd-file="$tmp"
      if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
      fi
      ${pkgs.coreutils}/bin/rm -f -- "$tmp"
    }
  ''
  + (builtins.readFile ./non_nix.bash)
)
