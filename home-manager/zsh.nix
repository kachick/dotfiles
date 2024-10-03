{
  config,
  lib,
  pkgs,
  homemade-pkgs,
  ...
}:

{
  services.gpg-agent.enableZshIntegration = true;
  programs.starship.enableZshIntegration = true;
  programs.direnv.enableZshIntegration = true;
  programs.zoxide.enableZshIntegration = true;
  programs.fzf.enableZshIntegration = true;
  # Avoid nested zellij in host and remote login as container
  programs.zellij.enableZshIntegration = false;

  # https://nixos.wiki/wiki/Zsh
  # https://zsh.sourceforge.io/Doc/Release/Options.html
  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/zsh.nix
  # You should consider the loading order: https://medium.com/@rajsek/zsh-bash-startup-files-loading-order-bashrc-zshrc-etc-e30045652f2e
  programs.zsh = {
    enable = true;

    # BE CAREFUL WHEN REFACTOR: Why can't I use let ~ in or rec for this dotDir and ${config.xdg.configHome}?
    # zsh manager always append $HOME as the prefix, so you can NOT write as `"${config.xdg.configHome}/zsh"`
    # https://github.com/nix-community/home-manager/blob/8c731978f0916b9a904d67a0e53744ceff47882c/modules/programs/zsh.nix#L25C3-L25C10
    dotDir = ".config/zsh";

    localVariables = {
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
    # https://github.com/nix-community/home-manager/blob/8c731978f0916b9a904d67a0e53744ceff47882c/modules/programs/zsh.nix#L325C7-L329
    # https://github.com/nix-community/home-manager/blob/8c731978f0916b9a904d67a0e53744ceff47882c/modules/programs/zsh.nix#L368-L372
    # The default is "autoload -U compinit && compinit", I can not accept the path and speed
    initExtraBeforeCompInit = ''
      _elapsed_seconds_for() {
        local -r target_path="$1"
        echo "$(("$(${lib.getBin pkgs.coreutils}/bin/date +"%s")" - "$(${lib.getBin pkgs.coreutils}/bin/stat --format='%Y' "$target_path")"))"
      }

      # path - https://stackoverflow.com/a/48057649/1212807
      # speed - https://gist.github.com/ctechols/ca1035271ad134841284
      # both - https://github.com/kachick/dotfiles/pull/155
      _compinit_with_interval() {
        local -r dump_dir="${config.xdg.cacheHome}/zsh"
        local -r dump_path="$dump_dir/zcompdump-$ZSH_VERSION"
        # seconds * minutes * hours
        local -r threshold="$((60 * 60 * 3))"

        if [ -e "$dump_path" ] && [ "$(_elapsed_seconds_for "$dump_path")" -le "$threshold" ]; then
          # https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Use-of-compinit
          # -C omit to check new functions
          compinit -C -d "$dump_path"
        else
          ${lib.getBin pkgs.coreutils}/bin/mkdir -p "$dump_dir"
          compinit -d "$dump_path"
          ${lib.getBin pkgs.coreutils}/bin/touch "$dump_path" # Ensure to update timestamp
        fi
      }
    '';
    completionInit = ''
      # `autoload` enable to use compinit
      autoload -Uz compinit && _compinit_with_interval
      # for cargo-make
      # AFAIK, it does not take path options. And fast for now, so needless to be cached
      autoload -U +X bashcompinit && bashcompinit
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
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi

        ;;
      esac

      # https://gist.github.com/ctechols/ca1035271ad134841284?permalink_comment_id=3401477#gistcomment-3401477
      skip_global_compinit=1

      if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi # added by Nix installer

      # Put the special config in each machine if you want to avoid symlinks by Nix
      # https://github.com/nix-community/home-manager/issues/3090#issue-1303753447
      if [ -e '${config.xdg.configHome}/zsh/.zshenv.local' ]; then
        source '${config.xdg.configHome}/zsh/.zshenv.local'
      fi
    '';

    initExtra = ''
      typeset -g HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=blue,bold'
      typeset -g HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS='i'
      typeset -g HISTORY_SUBSTRING_SEARCH_FUZZY='true'

      setopt correct
      unsetopt BEEP

      setopt hist_reduce_blanks
      setopt hist_save_no_dups
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

      source "${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh"
      source "${pkgs.podman}/share/zsh/site-functions/_podman"
      # cargo-make recommends to use bash completions for zsh
      source "${homemade-pkgs.cargo-make-completions}/share/bash-completion/completions/makers-completion.bash"

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

      # Do not use absolute path for makers to respect current version in each repository
      # No need adding for `cargo-make`, it requires subcommand as `cargo-make make`. I'm avoiding the style
      _fzf_complete_makers() {
        _fzf_complete --multi --reverse --prompt="makers> " --nth 1 -- "$@" < <(
          # Don't use `--output-format autocomplete`, it truncates task description
          makers --list-all-steps | ${lib.getExe pkgs.ripgrep} --regexp='^\w+ -'
        )
      }

      _fzf_complete_makers_post() {
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

      source "${../dependencies/dprint/completions.zsh}"

      # Disable `Ctrl + S(no output tty)`
      ${lib.getBin pkgs.coreutils}/bin/stty stop undef

      # https://unix.stackexchange.com/a/3449
      source_sh () {
        emulate -LR sh
        . "$@"
      }

      source_sh "${homemade-pkgs.posix_shared_functions}"

      if [ 'linux' = "$TERM" ]; then
        disable_blinking_cursor
      fi

      # https://superuser.com/a/902508/120469
      # https://github.com/zsh-users/zsh-autosuggestions/issues/259
      zshaddhistory() { whence ''${''${(z)1}[1]} >| /dev/null || return 1 }

      # Same as .zshenv.local
      if [ -e '${config.xdg.configHome}/zsh/.zshrc.local' ]; then
        source '${config.xdg.configHome}/zsh/.zshrc.local'
      fi
    '';

    # Use one of profileExtra or loginExtra. Not both
    profileExtra = ''
      # TODO: Switch to pkgs.zsh from current zsh in darwin

      if [[ "$OSTYPE" == darwin* ]]; then
        # TODO: May move to sessionVariables
        export BROWSER='open'

        # Microsoft recommends this will be written in ~/.zprofile,
        if [ -x '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code' ]; then
          export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
        fi
      fi
    '';
  };
}
