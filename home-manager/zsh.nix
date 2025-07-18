{
  config,
  lib,
  pkgs,
  ...
}:

# NOTE:
# Most frustrated part of zsh is how to keep speed with the slow completions.
# See https://github.com/zsh-users/zsh/blob/zsh-5.9/Completion/compinit for the options.

let
  ZCOMPDUMP_CACHE_DIR = "${config.xdg.cacheHome}/zsh";
  ZCOMPDUMP_CACHE_PATH = "${ZCOMPDUMP_CACHE_DIR}/zcompdump-${pkgs.zsh.version}";
in
{
  services.gpg-agent.enableZshIntegration = true;
  programs.starship.enableZshIntegration = true;
  programs.direnv.enableZshIntegration = true;
  programs.zoxide.enableZshIntegration = true;
  programs.fzf.enableZshIntegration = false; # GH-1192: Don't enable fzf integrations, it makes shell startup slower. Load only key-bindings if required.
  programs.television.enableZshIntegration = false; # Conflict with fzf by default
  programs.zellij.enableZshIntegration = false; # Avoid nested zellij in host and remote login as container

  home.activation.refreshZcompdumpCache = config.lib.dag.entryAnywhere ''
    if [[ -v oldGenPath && -f '${ZCOMPDUMP_CACHE_PATH}' ]]; then
      # Enforcing to clear old cache, because of just omitting -C kept the command names
      ${lib.getBin pkgs.coreutils}/bin/rm '${ZCOMPDUMP_CACHE_PATH}'
    fi
  '';

  # https://nixos.wiki/wiki/Zsh
  # https://zsh.sourceforge.io/Doc/Release/Options.html
  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/programs/zsh.nix
  # You should consider the loading order: https://medium.com/@rajsek/zsh-bash-startup-files-loading-order-bashrc-zshrc-etc-e30045652f2e
  programs.zsh = {
    enable = true;

    # BE CAREFUL WHEN REFACTOR: Why can't I use let ~ in or rec for this dotDir and ${config.xdg.configHome}?
    # zsh manager always append $HOME as the prefix, so you can NOT write as `"${config.xdg.configHome}/zsh"`
    # https://github.com/nix-community/home-manager/blob/8c731978f0916b9a904d67a0e53744ceff47882c/modules/programs/zsh.nix#L25C3-L25C10
    dotDir = ".config/zsh";

    localVariables = {
      inherit ZCOMPDUMP_CACHE_DIR ZCOMPDUMP_CACHE_PATH;

      # This is a minimum note for home-manager dead case such as https://github.com/kachick/dotfiles/issues/680#issuecomment-2353820508
      PROMPT = ''
        %~ %? %#
        > '';
    };

    history = {
      # in memory
      size = 84000;

      # in file
      save = 42000;
      path = "${config.xdg.stateHome}/zsh/history";

      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      saveNoDups = true;
      findNoDups = true;

      # https://askubuntu.com/questions/999923/syntax-in-history-ignore
      # https://github.com/zsh-users/zsh/blob/aa8e4a02904b3a1c4b3064eb7502d887f7de958b/Src/hist.c#L3006-L3015
      ignorePatterns = [
        "cd *"
        "pushd *"
        "popd *"
        "z *"
        "ls *"
        "ll *"
        "la *"
        "rm *"
        "rmdir *"
        "git show *"
        "tldr *"
        "exit"
      ];

      # Hist memory size should be grater than saving file size if enabled
      expireDuplicatesFirst = true;

      extended = true;
      share = true;
    };

    historySubstringSearch = {
      enable = true;
    };

    syntaxHighlighting = {
      enable = true;
      # Candidates: https://wiki.archlinux.org/title/zsh#Colors
      # 0-7, 7 words(starship "purple" is "magenta" here), or #COLORCODE style.
      styles = {
        unknown-token = "fg=magenta";
      };

      # Candidates: https://github.com/zsh-users/zsh-syntax-highlighting/blob/e0165eaa730dd0fa321a6a6de74f092fe87630b0/docs/highlighters.md
      highlighters = [
        "brackets"
        "pattern" # Not pattern"s"!
        "root"
      ];

      # This will work if you enabled "pattern" highlighter
      # https://github.com/zsh-users/zsh-syntax-highlighting/blob/e0165eaa730dd0fa321a6a6de74f092fe87630b0/docs/highlighters/pattern.md
      patterns = builtins.listToAttrs (
        (map (typo: {
          name = typo;
          value = "fg=red,bold";
        }))
          (
            [
              "rm -rf *"
              # typo of "-a -m"
              "-a- m"
            ]
            ++ import ./typo_commands.nix
          )
      );
    };

    autosuggestion = {
      enable = true;
    };

    # NOTE: enabling without tuning makes much slower zsh as +100~200ms execution time
    #       And the default path is not intended, so you SHOULD update `completionInit`
    enableCompletion = true;

    completionInit = ''
      # `autoload` enable to use compinit
      autoload -Uz compinit && _compinit_with_interval
    '';

    # Setting bindkey
    # https://github.com/nix-community/home-manager/blob/8c731978f0916b9a904d67a0e53744ceff47882c/modules/programs/zsh.nix#L28
    # https://qiita.com/yoshikaw/items/fe4aca1110979e223f7e
    defaultKeymap = "emacs";

    # home-manager path will set in `programs.home-manager.enable = true`;
    envExtra = ''
      case ''${OSTYPE} in
      darwin*)
        # Disables the annoy /usr/libexec/path_helper in /etc/zprofile
        # - Even after this option, /etc/zshenv will be loaded
        # - Some crucial PATH will be hidden they are installed by non nix layer. For example: vscode
        setopt no_global_rcs

        # See https://github.com/kachick/dotfiles/issues/159 and https://github.com/NixOS/nix/issues/3616
        # nix loaded programs may be used in zshrc and non interactive mode, so this workaround should be included in zshenv
        if [ -f '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi

        ;;
      esac

      # https://gist.github.com/ctechols/ca1035271ad134841284?permalink_comment_id=3401477#gistcomment-3401477
      skip_global_compinit=1

      if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi # added by Nix installer

      # Put the special config in each machine if you want to avoid symlinks by Nix
      # https://github.com/nix-community/home-manager/issues/3090#issue-1303753447
      if [ -f '${config.xdg.configHome}/zsh/.zshenv.local' ]; then
        source '${config.xdg.configHome}/zsh/.zshenv.local'
      fi
    '';

    # https://github.com/nix-community/home-manager/blob/ae755329092c87369b9e9a1510a8cf1ce2b1c708/modules/programs/zsh.nix#L513-L527
    initContent =
      let
        # https://github.com/nix-community/home-manager/blob/8c731978f0916b9a904d67a0e53744ceff47882c/modules/programs/zsh.nix#L325C7-L329
        # https://github.com/nix-community/home-manager/blob/8c731978f0916b9a904d67a0e53744ceff47882c/modules/programs/zsh.nix#L368-L372
        # The default is "autoload -U compinit && compinit", I can not accept the path and speed
        # Replacement of initExtraBeforeCompInit, it looks bit hacky. Track discussion in https://github.com/nix-community/home-manager/pull/6664
        beforeCompInit = lib.mkOrder 550 ''
          _elapsed_seconds_for() {
            local -r target_path="$1"
            echo "$(("$(${lib.getBin pkgs.coreutils}/bin/date +"%s")" - "$(${lib.getBin pkgs.coreutils}/bin/stat --format='%Y' "$target_path")"))"
          }

          # path - https://stackoverflow.com/a/48057649/1212807
          # speed - https://gist.github.com/ctechols/ca1035271ad134841284
          # both - https://github.com/kachick/dotfiles/pull/155
          _compinit_with_interval() {
            # seconds * minutes * hours
            local -r threshold="$((60 * 60 * 3))"

            if [ -f "$ZCOMPDUMP_CACHE_PATH" ] && [ "$(_elapsed_seconds_for "$ZCOMPDUMP_CACHE_PATH")" -le "$threshold" ]; then
              # https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Use-of-compinit
              # -C omit to check new functions
              compinit -C -d "$ZCOMPDUMP_CACHE_PATH"
            else
              # For refreshing the cache

              ${lib.getBin pkgs.coreutils}/bin/mkdir -p "$ZCOMPDUMP_CACHE_DIR"
              compinit -d "$ZCOMPDUMP_CACHE_PATH"
              ${lib.getBin pkgs.coreutils}/bin/touch "$ZCOMPDUMP_CACHE_PATH" # Ensure to update timestamp
            fi
          }
        '';

        # Be aware that `setopt` and `unsetopt` might be silently overridden by recent changes in zsh module behavior.
        # For example, an option set in https://github.com/kachick/dotfiles/blame/90265811fcbc1b500d14a4b154ab568e90bb7ff2/home-manager/zsh.nix#L211
        # was silently overridden by changes introduced in:
        # - https://github.com/nix-community/home-manager/pull/6227
        # - https://github.com/kachick/dotfiles/pull/1178#issuecomment-2888101460
        generalAfterCompInit = lib.mkOrder 1000 ''
          typeset -g HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=blue,bold'
          typeset -g HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS='i'
          typeset -g HISTORY_SUBSTRING_SEARCH_FUZZY='true'

          setopt correct
          unsetopt BEEP

          setopt hist_reduce_blanks
          setopt hist_no_store
          setopt HIST_NO_FUNCTIONS
          # https://apple.stackexchange.com/questions/405246/zsh-comment-character
          setopt interactivecomments

          # Needed in my env for `Ctrl + </>` https://unix.stackexchange.com/a/58871
          bindkey ";5C" forward-word
          bindkey ";5D" backward-word

          # https://github.com/starship/starship/blob/0d98c4c0b7999f5a8bd6e7db68fd27b0696b3bef/docs/uk-UA/advanced-config/README.md#change-window-title
          function set_win_title() {
            echo -ne "\033]0; $(${lib.getBin pkgs.coreutils}/bin/basename "$PWD") \007"
          }
          precmd_functions+=(set_win_title)

          source "${pkgs.fzf}/share/fzf/key-bindings.zsh" # Don't load completions. It much made shell startup slower
          source "${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh"

          # source only load first path. See https://stackoverflow.com/questions/14677936/source-multiple-files-in-zshrc-with-wildcard
          for file in ${../dependencies/zsh}/*; do
              source "$file"
          done

          # fzf completions are also possible to be used in bash, but it overrides default completions with the registering
          # So currently injecting only in zsh

          _fzf_complete_zellij() {
            local -r subcmd=''${1#* }
            if [[ "$subcmd" == kill-session* ]]; then
              _fzf_complete --multi --reverse --prompt="zellij(active)> " --ansi --nth 1 -- "$@" < <(
                ${lib.getExe pkgs.zellij} list-sessions | ${lib.getExe pkgs.ripgrep} --invert-match --fixed-strings -e 'EXITED'
              )
            else
              _fzf_complete --multi --reverse --prompt="zellij> " --ansi --nth 1 -- "$@" < <(
                ${lib.getExe pkgs.zellij} list-sessions
              )
            fi
          }

          _fzf_complete_zellij_post() {
            ${lib.getBin pkgs.coreutils}/bin/cut --delimiter=' ' --fields=1
          }

          # Do not use absolute path for go-task to respect current version in each repository
          _fzf_complete_task() {
            _fzf_complete --multi --reverse --prompt="task> " -- "$@" < <(
              task --list-all | ${lib.getExe pkgs.ripgrep} --regexp='^\* (.+)' --replace='$1'
            )
          }

          _fzf_complete_task_post() {
            ${lib.getExe pkgs.ripgrep} --regexp='(\S+?): ' --replace='$1'
          }

          # Disable `Ctrl + S(no output tty)`
          ${lib.getBin pkgs.coreutils}/bin/stty stop undef

          # https://unix.stackexchange.com/a/3449
          source_sh () {
            emulate -LR sh
            . "$@"
          }

          source_sh "${pkgs.my.posix_shared_functions}"

          # To prefer ISO 8601 format. See https://unix.stackexchange.com/questions/62316/why-is-there-no-euro-english-locale
          # And don't set this in home-manager's sessionVariables. It makes much confusion behavior or bugs when using GNOME (or all of DE)
          export LC_TIME='en_DK.UTF-8'

          if [ 'linux' = "$TERM" ]; then
            adjust_to_linux_vt
          fi

          rg-fzf-widget() {
            "${lib.getExe pkgs.my.rg-fzf}" "$LBUFFER"
            zle reset-prompt
          }

          _tv_text_then_edit() {
            local -r tv_result="$("${lib.getExe pkgs.television}" text --input "$LBUFFER")"
            if [[ -n "$tv_result" ]]; then
              "$EDITOR" "$tv_result"
            fi

            zle reset-prompt
          }

          # television is much faster than ripgrep + fzf solution especially for full-text search
          # So consider to prefer it after portrait mode is available
          zle     -N            rg-fzf-widget
          bindkey -M emacs '^F' rg-fzf-widget
          bindkey -M vicmd '^F' rg-fzf-widget
          bindkey -M viins '^F' rg-fzf-widget

          # https://superuser.com/a/902508/120469
          # https://github.com/zsh-users/zsh-autosuggestions/issues/259
          zshaddhistory() { whence ''${''${(z)1}[1]} >| /dev/null || return 1 }

          # Same as .zshenv.local
          if [ -f '${config.xdg.configHome}/zsh/.zshrc.local' ]; then
            source '${config.xdg.configHome}/zsh/.zshrc.local'
          fi
        '';
      in
      lib.mkMerge [
        beforeCompInit
        generalAfterCompInit
      ];

    # Useable one of profileExtra or loginExtra. Do not specify both.
  };
}
