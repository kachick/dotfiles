{ config, ... }:

{
  programs.starship.enableZshIntegration = true;
  programs.direnv.enableZshIntegration = true;
  programs.zoxide.enableZshIntegration = true;
  programs.fzf.enableZshIntegration = true;

  # https://nixos.wiki/wiki/Zsh
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/zsh.nix
  programs.zsh = {
    enable = true;

    # How about to point `xdg.configFile`?
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
    enableSyntaxHighlighting = true;
    enableAutosuggestions = true;
    enableCompletion = true;

    # home-manager path will set in `programs.home-manager.enable = true`;
    envExtra = ''
      # https://wiki.archlinux.jp/index.php/XDG_Base_Directory
      # https://www.reddit.com/r/zsh/comments/tpwx9t/zcompcache_vs_zcompdump/
      zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

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

      eval "$($XDG_DATA_HOME/rtx/bin/rtx activate -s zsh)"

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
