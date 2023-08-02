{ config, lib, pkgs, ... }:

{
  programs.starship.enableZshIntegration = true;
  programs.direnv.enableZshIntegration = true;
  programs.zoxide.enableZshIntegration = true;
  programs.fzf.enableZshIntegration = true;
  programs.rtx.enableZshIntegration = true;

  # https://nixos.wiki/wiki/Zsh
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/zsh.nix
  programs.zsh = {
    enable = true;

    # zsh manager always append $HOME as the prefix, so you can NOT write as `"${config.xdg.configHome}/zsh"`
    # https://github.com/nix-community/home-manager/blob/8c731978f0916b9a904d67a0e53744ceff47882c/modules/programs/zsh.nix#L25C3-L25C10
    dotDir = ".config/zsh";

    history = {
      # in memory
      size = 100000;

      # in file
      save = 4200000;
      path = "${config.xdg.stateHome}/zsh/history";

      ignoreDups = true;
      ignoreSpace = true;

      extended = true;
      share = true;
    };

    historySubstringSearch = {
      enable = true;
    };

    syntaxHighlighting.enable = true;

    enableAutosuggestions = true;

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
          mkdir -p "$dump_dir"
          compinit -d "$dump_path"
        fi
      }
    '';
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
      # https://gist.github.com/ctechols/ca1035271ad134841284?permalink_comment_id=3401477#gistcomment-3401477
      skip_global_compinit=1

      if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi # added by Nix installer
    '';

    initExtra = ''
      typeset -g HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=blue,bold'
      typeset -g HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS='i'
      typeset -g HISTORY_SUBSTRING_SEARCH_FUZZY='true'

      setopt correct
      unsetopt BEEP

      setopt hist_ignore_all_dups
      setopt hist_reduce_blanks
      setopt hist_save_no_dups
      setopt hist_no_store

      # Needed in my env for `Ctrl + </>` https://unix.stackexchange.com/a/58871
      bindkey ";5C" forward-word
      bindkey ";5D" backward-word

      case ''${OSTYPE} in
      darwin*)
        test -e "''${HOME}/.iterm2_shell_integration.zsh" && source "''${HOME}/.iterm2_shell_integration.zsh"
        ;;
      esac

      # https://github.com/starship/starship/blob/0d98c4c0b7999f5a8bd6e7db68fd27b0696b3bef/docs/uk-UA/advanced-config/README.md#change-window-title
      function set_win_title() {
        echo -ne "\033]0; $(basename "$PWD") \007"
      }
      precmd_functions+=(set_win_title)

      zshaddhistory() { whence ''${''${(z)1}[1]} >| /dev/null || return 1 }
    '';

    # TODO: May move to sessionVariables
    profileExtra = ''
      if [[ "$OSTYPE" == darwin* ]]; then
        export BROWSER='open'
      fi
    '';
  };
}
