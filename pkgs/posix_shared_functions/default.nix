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

  # See the reason in GH-660
  # Original scheme: https://gist.github.com/cocopon/1d481941907d12db7a0df2f8806cfd41
  apply_iceberg() {
    # Blue. Mandatory to be changed from ANSI
    echo -en "\e]P484a0c6"
    echo -en "\e]PC91acd1"

    # Black
    echo -en "\e]P01e2132"
    echo -en "\e]P86b7089"

    # Red
    echo -en "\e]P1e27878"
    echo -en "\e]P9e98989"

    # Green
    echo -en "\e]P2b4be82"
    echo -en "\e]PAc0ca8e"

    # Yellow
    echo -en "\e]P3e2a478"
    echo -en "\e]PBe9b189"

    # Magenta
    echo -en "\e]P5a093c7"
    echo -en "\e]PDada0d3"

    # White
    echo -en "\e]P7c6c8d1"
    echo -en "\e]PFd2d4de"
  }
''
