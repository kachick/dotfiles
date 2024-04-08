{ pkgs, edge-pkgs, ... }:

# - Tiny tools by me, they may be rewritten with another language.
# - Aliases across multiple shells
let
  la = pkgs.writeShellApplication {
    name = "la";
    runtimeInputs = with pkgs; [ eza ];
    text = ''
      eza --long --all --group-directories-first --color=always "$@"
    '';
  };
in
[
  (pkgs.writeShellApplication {
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
  })

  (pkgs.writeShellApplication {
    name = "updeps";
    # Do no include "nix" in inputs: https://github.com/NixOS/nix/issues/5473
    runtimeInputs = [ edge-pkgs.mise ];
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
  })

  la

  (pkgs.writeShellApplication {
    name = "lat";
    runtimeInputs = [ la ];
    text = ''
      la --tree "$@"
    '';
  })

  (pkgs.writeShellApplication {
    name = "walk";
    runtimeInputs = with pkgs; [
      edge-pkgs.fzf
      bat
      micro
    ];
    text = ''
      # TODO: Apply walker-* options since https://github.com/NixOS/nixpkgs/pull/295978 is useable
      eval "$EDITOR" "$(fzf --preview 'bat --color=always {}' --preview-window '~3')"
    '';
  })

  # Why need the wrapper?
  #   nixpkgs provide 4.9.3 is not including podman-remote.
  #   https://github.com/NixOS/nixpkgs/blob/e3474e1d1e53b70e2b2af73ea26d6340e82f6b8b/pkgs/applications/virtualization/podman/default.nix#L104-L108
  (pkgs.writeShellApplication {
    name = "podman";
    runtimeInputs = [ edge-pkgs.mise ];
    text = ''
      mise exec podman@latest -- podman "$@"
    '';
  })

  (pkgs.writeShellApplication {
    name = "zj";
    runtimeInputs = with pkgs; [
      coreutils
      zellij
    ];
    text = ''
      name="$(basename "$PWD")"

      zellij attach "$name" || zellij --session "$name"
    '';
  })

  (pkgs.writeShellApplication {
    name = "p";
    runtimeInputs = with pkgs; [ nix ];
    text = ''
      # Needless to trim the default command, nix-shell only runs last command if given multiple.
      nix-shell --command "$SHELL" --packages "$@"
    '';
  })

  (pkgs.writeShellApplication {
    name = "g";
    runtimeInputs = with pkgs; [ git ];
    text = ''
      git "$@"
    '';
  })

  (pkgs.writeShellApplication {
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
  })

  (pkgs.writeShellApplication {
    name = "fzf-bind-posix-shell-history-to-git-commit-message";
    runtimeInputs = with pkgs; [
      git
      edge-pkgs.fzf
      edge-pkgs.ruby_3_3
    ];
    text = ''
      # Avoiding nested single quote use
      bind="$(
      cat<<'EOF'
      enter:become(echo '`{}`' | git commit -a -F -)
      EOF
      )"

      # Why ruby?
      # - bash keeps whitespace prefix even specified -n option for fc -l
      # - lstrip is not enough for some history
      # - Keep line-end in fzf input
      # shellcheck disable=SC2016 disable=SC2086
      ruby -e 'STDIN.each { |line| puts line.strip }' | \
        fzf --height ''${FZF_TMUX_HEIGHT:-40%} ''${FZF_DEFAULT_OPTS-} -n2..,.. --scheme=history --bind "$bind"
    '';
    meta = {
      description = "Used in git alias";
    };
  })

  (pkgs.writeShellApplication {
    name = "todo";
    runtimeInputs = with pkgs; [
      git
      edge-pkgs.fzf
      micro
    ];
    text = ''
      git grep --perl-regexp --line-number --column --color=always '\b(?<=TODO|FIXME|BUG)\b\S+' | \
        fzf --ansi --delimiter : --nth 4.. --bind 'enter:become(micro -parsecursor=true {1}:{2}:{3})'
    '';
    meta = {
      description = "List todo family";
    };
  })

  (pkgs.writeShellApplication {
    name = "ghqf";
    runtimeInputs = with pkgs; [
      ghq
      edge-pkgs.fzf
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
  })

  (pkgs.writeShellApplication {
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
  })
]
