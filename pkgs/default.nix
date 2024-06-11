{ pkgs, ... }:
# fzf
#
# --preview: the placeholder will be quoted by singlequote, so do not add excess double quote as "{}". This will be evaluated the given `` and $()
# --nth: Match there
# --with-nth: Whole display and outputs. None of only outputs: See https://github.com/junegunn/fzf/issues/1323
# --bind 'enter:become(...)': Replace process, and no execution if not match
# --ansi: Handle colored input, but remember the output is dirty with the ANSI for another tools. You may need strip them before use.

# - Tiny tools by me, they may be rewritten with another language.
# - Aliases across multiple shells
rec {
  bump_completions = pkgs.writeShellApplication {
    name = "bump_completions";
    runtimeInputs = with pkgs; [
      git
      podman
      dprint
    ];
    text = ''
      podman completion bash > ./dependencies/podman/completions.bash
      podman completion zsh > ./dependencies/podman/completions.zsh
      podman completion fish > ./dependencies/podman/completions.fish

      git add ./dependencies/podman
      # https://stackoverflow.com/q/34807971
      git update-index -q --really-refresh
      git diff-index --quiet HEAD || git commit -m 'Update podman completions' ./dependencies/podman

      dprint completions bash > ./dependencies/dprint/completions.bash
      dprint completions zsh > ./dependencies/dprint/completions.zsh
      dprint completions fish > ./dependencies/dprint/completions.fish

      git add ./dependencies/dprint
      git update-index -q --really-refresh
      git diff-index --quiet HEAD || git commit -m 'Update dprint completions' ./dependencies/dprint
    '';
    meta = {
      description = "Bump shell completions with cached files to make faster";
    };
  };

  check_no_dirty_xz_in_nix_store = pkgs.writeShellApplication {
    name = "check_no_dirty_xz_in_nix_store";
    runtimeInputs = with pkgs; [ fd ];
    text = ''
      # nix store should have xz: https://github.com/NixOS/nixpkgs/blob/b96bc828b81140dd3fb096b4e66a6446d6d5c9dc/doc/stdenv/stdenv.chapter.md?plain=1#L177
      # You can't use --max-results instead of --has-results even if you want the log, it always returns true
      fd '^\w+-xz-[0-9\.]+\.drv' --search-path /nix/store --has-results

      # Why toggling errexit and return code here: https://github.com/kachick/times_kachick/issues/278
      set +o errexit
      fd '^\w+-xz-5\.6\.[01]\.drv' --search-path /nix/store --has-results
      fd_return_code="$?" # Do not directly use the $? to prevent feature broken if inserting another command before check
      set -o errexit
      [[ "$fd_return_code" -eq 1 ]]
    '';
    meta = {
      description = "Prevent #530 (around CVE-2024-3094)";
    };
  };

  safe_quote_backtik = pkgs.writeShellApplication {
    name = "safe_quote_backtik";
    text = ''
      quote='`'
      message="$1"
      echo "$quote$message$quote"
    '';
    meta = {
      description = "Quote `body` without command executions";
    };
  };

  bench_shells = pkgs.writeShellApplication {
    name = "bench_shells";
    runtimeInputs = with pkgs; [
      hyperfine
      zsh
      bashInteractive
      fish
    ];
    text = ''
      # ~ my feeling ~
      # 50ms : blazing fast!
      # 110ms : acceptable
      # 150ms : slow
      # 200ms : 1980s?
      # 300ms : much slow!

      # zsh should be first, because it often makes much slower with the completion
      hyperfine --warmup 1 --runs 5 \
        'zsh --interactive -c exit' \
        'bash -i -c exit' \
        'fish --interactive --command exit'
    '';
  };

  updeps = pkgs.writeShellApplication {
    name = "updeps";
    # Do no include "nix" in inputs: https://github.com/NixOS/nix/issues/5473
    runtimeInputs = with pkgs; [ mise ];
    text = ''
      echo 'this updater assume you have the privilege and sudo command'

      set -x

      case ''${OSTYPE} in
      linux*)
        sudo apt update --yes && sudo apt upgrade --yes
        ;;
      darwin*)
        softwareupdate --install --recommended
        ;;
      esac

      sudo -i nix upgrade-nix

      mise plugins update
    '';
  };

  la = pkgs.writeShellApplication {
    name = "la";
    runtimeInputs = with pkgs; [ eza ];
    text = ''
      eza --long --all --group-directories-first --color=always "$@"
    '';
  };

  lat = pkgs.writeShellApplication {
    name = "lat";
    runtimeInputs = [ la ];
    text = ''
      la --tree "$@"
    '';
  };

  walk = pkgs.writeShellApplication {
    name = "walk";
    runtimeInputs = with pkgs; [
      fzf
      bat
      micro
    ];
    text = ''
      # shellcheck disable=SC2016
      fzf --preview 'bat --color=always {}' --preview-window '~3' --bind 'enter:become(command "$EDITOR" {})'
    '';
  };

  # Why need the wrapper?
  #   nixpkgs provide 4.9.3 is not including podman-remote.
  #   https://github.com/NixOS/nixpkgs/blob/e3474e1d1e53b70e2b2af73ea26d6340e82f6b8b/pkgs/applications/virtualization/podman/default.nix#L104-L108
  podman = pkgs.writeShellApplication {
    name = "podman";
    runtimeInputs = with pkgs; [ mise ];
    text = ''
      mise exec podman@latest -- podman "$@"
    '';
  };

  zj = pkgs.writeShellApplication {
    name = "zj";
    runtimeInputs = with pkgs; [
      coreutils
      zellij
    ];
    text = ''
      name="$(basename "$PWD")"

      zellij attach "$name" || zellij --session "$name"
    '';
  };

  p = pkgs.writeShellApplication {
    name = "p";
    runtimeInputs = with pkgs; [ nix ];
    text = ''
      # Needless to trim the default command, nix-shell only runs last command if given multiple.
      nix-shell --command "$SHELL" --packages "$@"
    '';
  };

  g = pkgs.writeShellApplication {
    name = "g";
    runtimeInputs = with pkgs; [ git ];
    text = ''
      git "$@"
    '';
  };

  git-delete-merged-branches = pkgs.writeShellApplication {
    name = "git-delete-merged-branches";
    runtimeInputs = with pkgs; [
      git
      coreutils
      findutils
    ];
    text = ''
      # Care these traps if you change this code
      #   - Prefer git built-in features to filter as possible, handling correct regex is often hard for human
      #   - grep returns false if empty, it does not fit for pipefail use. --no-run-if-empty as xargs does not exists in the grep options
      #   - Always specify --sort to ensure it can be used in comm command. AFAIK, refname is most fit key here.
      #     Make sure, this result should not be changed even if you changed in global git config with git.nix
      #     Candidates: https://github.com/git/git/blob/3c2a3fdc388747b9eaf4a4a4f2035c1c9ddb26d0/ref-filter.c#L902-L959
      git branch --sort=refname --format='%(refname:short)' --list main master trunk develop development |
        comm --check-order -13 - <(git branch --sort=refname --format='%(refname:short)' --merged) |
        xargs --no-run-if-empty --max-lines=1 git branch --delete
    '';
  };

  fzf-bind-posix-shell-history-to-git-commit-message = pkgs.writeShellApplication {
    name = "fzf-bind-posix-shell-history-to-git-commit-message";
    runtimeInputs = with pkgs; [
      safe_quote_backtik
      git
      fzf
      ruby_3_3
    ];
    text = ''
      # Why ruby?
      # - bash keeps whitespace prefix even specified -n option for fc -l
      # - lstrip is not enough for some history
      # - Keep line-end in fzf input
      # shellcheck disable=SC2016 disable=SC2086
      ruby -e 'STDIN.each { |line| puts line.strip }' | \
        fzf --height ''${FZF_TMUX_HEIGHT:-40%} ''${FZF_DEFAULT_OPTS-} \
          -n2..,.. --scheme=history \
          --bind 'enter:become(safe_quote_backtik {} | git commit -a -F -)'
    '';
    meta = {
      description = "Used in git alias";
    };
  };

  todo = pkgs.writeShellApplication {
    name = "todo";
    runtimeInputs = with pkgs; [
      git
      fzf
      micro
      bat
    ];
    # open bat with line number in preview: https://github.com/sharkdp/bat/issues/1185#issuecomment-1301473901
    text = ''
      git grep --perl-regexp --line-number --column --color=always '\b(?<=TODO|FIXME|BUG)\b\S+' | \
        fzf --ansi --delimiter : --nth 4.. \
          --preview 'bat {1} --color=always --highlight-line={2}' --preview-window='~3,+{2}+3/4' \
          --bind 'enter:become(micro -parsecursor=true {1}:{2}:{3})'
    '';
    meta = {
      description = "List todo family";
    };
  };

  ghqf = pkgs.writeShellApplication {
    name = "ghqf";
    runtimeInputs = with pkgs; [
      ghq
      fzf
      la
    ];
    text = ''
      if [ $# -ge 1 ]; then
        query="$1"
      else
        query=""
      fi

      # shellcheck disable=SC2016
      ghq list | fzf --query "$query" --delimiter / --nth 3.. --preview 'la "$(
        ghq list --full-path --exact {}
      )"' --preview-window '~3'
    '';
    meta = {
      description = "ghq + fzf result";
    };
  };

  archive-home-files = pkgs.writeShellApplication {
    name = "archive-home-files";
    runtimeInputs = with pkgs; [
      gnutar
      ripgrep
      coreutils
    ];
    text = ''
      archive_basename="$1"
      # * Basically used in container for backup use, so keep fixed file name for the archive
      # * Specify the subdir of hm-gen/home-files, the dereference and recursive from generation root doesn't end
      tar --create --file="''${archive_basename}.tar.gz" --auto-compress --dereference --recursive --verify \
        --directory="$(home-manager generations | rg 'id \d+ -> /nix/store' | head -n1 | cut -d ' ' -f 7)/home-files" .
    '';
    meta = {
      description = "Backup dotfiles they are generated with home-manager. See #243";
    };
  };

  git-log-fzf = pkgs.writeShellApplication {
    name = "git-log-pp-fzf";
    runtimeInputs =
      with pkgs;
      [
        fzf
        coreutils
        git
        gh
        colorized-logs
        bat
      ]
      ++ (lib.optionals stdenv.isLinux [
        wslu # WSL helpers like `wslview`. It is used in open browser features in gh command
      ]);
    text = ''
      # source nixpkgs file does not work here: source "${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh"
      # https://github.com/junegunn/fzf-git.sh/blob/0f1e52079ffd9741eec723f8fd92aa09f376602f/fzf-git.sh#L118C1-L125C2
      _fzf_git_fzf() {
        fzf-tmux -p80%,60% -- \
          --layout=reverse --multi --height=50% --min-height=20 --border \
          --border-label-pos=2 \
          --color='header:italic:underline,label:blue' \
          --preview-window='right,50%,border-left' \
          --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' "$@"
      }

      # TODO: Replace enter:become with enter:execute. But didn't work for some ref as 2050a94
      _fzf_git_fzf --ansi --nth 1,3.. --no-sort --border-label '🪵 Logs' \
        --preview 'echo {} | \
          cut --delimiter " " --fields 2 --only-delimited | \
          ansi2txt | \
          xargs --no-run-if-empty --max-lines=1 git show --color=always | \
          bat --language=gitlog --color=always --style=plain --wrap=character' \
        --header $'CTRL-O (Open in browser) ╱ Enter (git show with bat)\n\n' \
        --bind 'ctrl-o:execute-silent(gh browse {2})' \
        --bind 'enter:become(git show --color=always {2} | bat --language=gitlog --color=always --style=plain --wrap=character)'
    '';
  };

  wait-and-squashmerge = pkgs.writeShellApplication {
    name = "wait-and-squashmerge";
    runtimeInputs = with pkgs; [
      gh
      micro
    ];
    text = ''
      readonly pr_number="$1"
      readonly subject_base="$2"
      commit_subject="$(echo "$subject_base" | micro)"
      readonly commit_subject

      gh pr checks "$pr_number" --interval 5 --watch --fail-fast && \
        gh pr merge "$pr_number" --delete-branch --squash --subject "$commit_subject"
    '';
  };

  prs = pkgs.writeShellApplication {
    name = "prs";
    runtimeInputs =
      with pkgs;
      [
        coreutils
        fzf
        gh
        micro
        wait-and-squashmerge
      ]
      ++ (lib.optionals stdenv.isLinux [
        wslu # WSL helpers like `wslview`. It is used in open browser features in gh command
      ]);
    # Don't use `gh --json --template`, golang template syntax cannot use if in pipe, so changing color for draft state will gone
    text = ''
      # shellcheck disable=SC2016
      GH_FORCE_TTY='50%' gh pr list --state 'open' | \
        fzf --ansi --header-lines=4 --nth 2.. \
          --preview 'GH_FORCE_TTY=$FZF_PREVIEW_COLUMNS gh pr view {1}' \
          --header $'ALT-C (Checkout) / CTRL-O (Open in browser)\nCTRL-S (Squash and merge) ╱ CTRL-M (Merge)\n\n' \
          --bind 'alt-c:become(gh pr checkout {1})' \
          --bind 'ctrl-o:execute-silent(gh pr view {1} --web)' \
          --bind 'ctrl-s:become(wait-and-squashmerge {1} {2..})' \
          --bind 'ctrl-m:become(gh pr checks {1} --interval 5 --watch --fail-fast && gh pr merge {1} --delete-branch)' \
          --bind 'enter:become(echo {1} | tr -d "#")'
    '';
  };
}
