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
let
  trim-github-user-prefix-for-reponame = pkgs.callPackage ../trim-github-user-prefix-for-reponame { };
  ghqf = pkgs.callPackage ../ghqf { };
  fzf-bind-posix-shell-history-to-git-commit-message =
    pkgs.callPackage ../fzf-bind-posix-shell-history-to-git-commit-message
      { };
in
pkgs.writeText "posix_shared_functions.sh" ''
  cdg() {
    local -r query_repoonly="$(echo "$1" | ${lib.getExe trim-github-user-prefix-for-reponame})"
    local -r repo="$(${lib.getExe ghqf} "$query_repoonly")"
    if [ -n "$repo" ]; then
      cd "$(${lib.getExe pkgs.ghq} list --full-path --exact "$repo")"
    fi
  }

  gg() {
    ${lib.getExe pkgs.ghq} get "$1" && cdg "$1"
  }

  cdt() {
    cd "$(${pkgs.coreutils}/bin/mktemp --directory)"
  }

  gch() {
    fc -nrl 1 | ${lib.getExe fzf-bind-posix-shell-history-to-git-commit-message}
  }
''
