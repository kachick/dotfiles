{ config, ... }:

{
  programs.starship.enableBashIntegration = true;
  programs.direnv.enableBashIntegration = true;
  programs.zoxide.enableBashIntegration = true;
  programs.fzf.enableBashIntegration = true;
  programs.rtx.enableBashIntegration = true;

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/bash.nix
  programs.bash = {
    enabled = true;

    shellOptions = [
      # Append to history file rather than replacing it.
      "histappend"

      # check the window size after each command and, if
      # necessary, update the values of LINES and COLUMNS.
      "checkwinsize"

      # Extended globbing.
      "extglob"
      "globstar"

      # Warn if closing shell with running jobs.
      "checkjobs"
    ];

    # Run even in non-interactive
    # bashrcExtra = ''
    #   # If not running interactively, don't do anything
    #   case $- in
    #   *i*) ;;
    #   *) return ;;
    #   esac
    # '';

    enableCompletion = true;

    historySize = 100000;
    historyFile = "${config.xdg.stateHome}/bash/history";
    historyFileSize = 4200000;
    historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
    historyIgnore = [ "ls" "cd" ];

    initExtra = ''
      # https://github.com/Bash-it/bash-it/blob/00062bfcb6c6a68cd2c9d2c76ed764e01e930e87/plugins/available/history-substring-search.plugin.bash
      if [[ ''${SHELLOPTS} =~ (vi|emacs) ]]; then
      	bind '"\e[A":history-substring-search-backward'
      	bind '"\e[B":history-substring-search-forward'
      fi

      # See https://github.com/kachick/times_kachick/issues/237
      #
      # Avoid nix provided bash on nix-shell makes broken bind, complete, color_prompt
      # Following part of ps... did referer to https://github.com/NixOS/nix/issues/3862#issuecomment-1611837272,
      # because non nested bash does not make this problem.
      # e.g
      #   cd ../
      #   rm ./the_repo/.envrc # Avoid direnv injection
      #   cd ./the_repo
      #   nix develop # the executed nix-shell does NOT have problems, so you can wrap as starship
      #   bash # this nested bash HAS problems without following ps... condition.
      if [[ -n "$IN_NIX_SHELL" && "$(ps -o uid= $PPID)" -eq "$UID" ]]; then
        in_nested_nix_bash="true"
      fi

      # set variable identifying the chroot you work in (used in the prompt below)
      if [ -z "''${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
        debian_chroot=$(cat /etc/debian_chroot)
      fi

      # set a fancy prompt (non-color, unless we know we "want" color)
      case "$TERM" in
      xterm-color | *-256color) color_prompt=yes ;;
      esac

      # uncomment for a colored prompt, if the terminal has the capability; turned
      # off by default to not distract the user: the focus in a terminal window
      # should be on the output of commands, not on the prompt
      #force_color_prompt=yes

      if [ -n "$force_color_prompt" ]; then
        if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
          # We have color support; assume it's compliant with Ecma-48
          # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
          # a case would tend to support setf rather than setaf.)
          color_prompt=yes
        else
          color_prompt=
        fi
      fi

      if [ "$color_prompt" = yes ] && [ -z "$in_nested_nix_bash" ]; then
        PS1='''''${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\[\033[01;34m\]\w\[\033[00m\]\$ '
      else
        PS1='''''${debian_chroot:+($debian_chroot)}\w\$ '
      fi
      unset color_prompt force_color_prompt

      if [ -z "$in_nested_nix_bash" ]; then
        # If this is an xterm set the title to user@host:dir
        case "$TERM" in
        xterm* | rxvt*)
          PS1="\[\e]0;''${debian_chroot:+($debian_chroot)} \w\a\]$PS1"
          ;;
        *) ;;

        esac
      fi


      # enable color support of ls and also add handy aliases
      if [ -x /usr/bin/dircolors ]; then
        (test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)") || eval "$(dircolors -b)"
        alias ls='ls --color=auto'
        #alias dir='dir --color=auto'
        #alias vdir='vdir --color=auto'

        alias grep='grep --color=auto'
        alias fgrep='fgrep --color=auto'
        alias egrep='egrep --color=auto'
      fi

      # https://github.com/starship/starship/blob/0d98c4c0b7999f5a8bd6e7db68fd27b0696b3bef/docs/uk-UA/advanced-config/README.md#change-window-title
      function set_win_title() {
        echo -ne "\033]0; $(basename "$PWD") \007"
      }
      # shellcheck disable=SC2034
      starship_precmd_user_func="set_win_title"
    '';

    logoutExtra = ''
      # when leaving the console clear the screen to increase privacy

      if [ "$SHLVL" = 1 ]; then
        [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
      fi
    '';
  };
}
