{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.gpg-agent.enableBashIntegration = true;
  programs.starship.enableBashIntegration = true;
  programs.direnv.enableBashIntegration = true;
  programs.zoxide.enableBashIntegration = true;
  programs.fzf.enableBashIntegration = false; # GH-1192: Don't enable fzf integrations, it makes shell startup slower. Load only key-bindings if required.
  programs.television.enableBashIntegration = false; # Conflict with fzf by default
  programs.zellij.enableBashIntegration = false; # Intentionally disabled for keeping stable bash

  # Used only in bash - https://unix.stackexchange.com/a/689403
  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/programs/readline.nix
  programs.readline = {
    enable = true;
    variables = {
      # https://man.archlinux.org/man/readline.3#bell
      #   option: audible, visible, none
      # https://unix.stackexchange.com/questions/73672/how-to-turn-off-the-beep-only-in-bash-tab-complete
      # https://github.com/nix-community/home-manager/blob/0841242b94638fcd010f7f64e56b7b1cad50c697/modules/programs/readline.nix
      bell-style = "none";

      # https://wiki.archlinux.jp/index.php/Readline
      # https://man.archlinux.org/man/readline.3
      completion-ignore-case = true;
      colored-stats = true;
      colored-completion-prefix = true;
      visible-stats = true;
      show-mode-in-prompt = false;
      show-all-if-ambiguous = true;
      echo-control-characters = false;
    };
  };

  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/programs/bash.nix
  programs.bash = {
    enable = true;

    # In macOS, default login shell is zsh now.
    # Keep the default as possible, but if you change the bash is the default even in macOS, you should care the path_helper problems
    # #503 and https://superuser.com/a/583502 may help you.

    sessionVariables = {
      # Cannot dynamically get from program.readline and cannot use XDG style in home-manager
      # https://github.com/nix-community/home-manager/blob/0841242b94638fcd010f7f64e56b7b1cad50c697/modules/programs/readline.nix#L72
      INPUTRC = "${config.home.homeDirectory}/.inputrc";
    };

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

    enableCompletion = true;

    historySize = 100000;
    historyFile = "${config.xdg.stateHome}/bash/history";
    historyFileSize = 4200000;
    historyControl = [
      "erasedups"
      "ignoredups"
      "ignorespace"
    ];
    # NOTE: I didn't check it should have different globs as zsh or not, at least the sepelator is not same.
    historyIgnore = [
      "cd"
      "pushd"
      "popd"
      "z"
      "ls"
      "ll"
      "la"
      "rm"
      "rmdir"
      "git show"
      "tldr"
      "exit"
    ];

    # For interactive shells. In .bashrc and after early return
    # https://github.com/nix-community/home-manager/blob/release-24.11/modules/programs/bash.nix#L221-L222
    # And https://techracho.bpsinc.jp/hachi8833/2021_07_08/66396 may help to understand why .bashrc
    #
    # Extracting because embedded here requires complex escape with nix multiline.
    #
    # Don't put shell delegation code into early phase than interactive check such as profileExtra and bashrcExtra , it blocks applying home.file on NixOS. See GH-680 for details
    # There is no ideal option in home-manager bash module for realizing first entry of the interactive shell. https://github.com/nix-community/home-manager/blob/f463902a3f03e15af658e48bcc60b39188ddf734/modules/programs/bash.nix#L227-L240
    # However initExtra is still better option than profileExtra.
    initExtra =
      ''
        # Don't put shell delegation code into early phase than interactive check
        # Switch to another shell when bash used as a login shell
        # Used same method as switching to fish
        # https://wiki.archlinux.org/title/fish#Setting_fish_as_interactive_shell_only
        if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "zsh" && -z ''${BASH_EXECUTION_STRING} && ''${SHLVL} == 1 ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${pkgs.zsh}/bin/zsh $LOGIN_OPTION
        fi

        # https://github.com/starship/starship/blob/0d98c4c0b7999f5a8bd6e7db68fd27b0696b3bef/docs/uk-UA/advanced-config/README.md#change-window-title
        function set_win_title() {
        	echo -ne "\033]0; $(${lib.getBin pkgs.coreutils}/bin/basename "$PWD") \007"
        }
        # shellcheck disable=SC2034
        starship_precmd_user_func="set_win_title"

        source "${pkgs.fzf}/share/fzf/key-bindings.bash" # Don't load completions. It much made shell startup slower
        source "${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh"

        # source does not load all paths. See https://stackoverflow.com/questions/1423352/source-all-files-in-a-directory-from-bash-profile
        for file in ${../dependencies/bash}/*; do
            source "$file"
        done

        # Disable `Ctrl + S(no output tty)`
        ${lib.getBin pkgs.coreutils}/bin/stty stop undef

        source "${pkgs.my.posix_shared_functions}"

        # To prefer ISO 8601 format. See https://unix.stackexchange.com/questions/62316/why-is-there-no-euro-english-locale
        # And don't set this in home-manager's sessionVariables. It makes much confusion behavior or bugs when using GNOME (or all of DE)
        export LC_TIME='en_DK.UTF-8'

        if [ 'linux' = "$TERM" ]; then
          adjust_to_linux_vt
        fi
      ''
      + builtins.readFile ./initExtra.bash;

    logoutExtra = ''
      # when leaving the console clear the screen to increase privacy

      if [ "$SHLVL" = 1 ]; then
        [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
      fi
    '';
  };
}
