{
  config,
  lib,
  pkgs,
  homemade-pkgs,
  edge-pkgs,
  ...
}:

{
  services.gpg-agent.enableBashIntegration = true;
  programs.starship.enableBashIntegration = true;
  programs.direnv.enableBashIntegration = true;
  programs.zoxide.enableBashIntegration = true;
  programs.fzf.enableBashIntegration = true;
  # Intentionally disabled for keeping stable bash
  programs.zellij.enableBashIntegration = false;

  # Used only in bash - https://unix.stackexchange.com/a/689403
  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/readline.nix
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

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/bash.nix
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

    # Switch to another shell when bash used as a login shell
    profileExtra = ''
      # Used same method as switching to fish
      # https://wiki.archlinux.org/title/fish#Setting_fish_as_interactive_shell_only
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "zsh" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.zsh}/bin/zsh $LOGIN_OPTION
      fi
    '';

    # For interactive shells. In .bashrc and after early return
    # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/bash.nix#L221-L222
    # And https://techracho.bpsinc.jp/hachi8833/2021_07_08/66396 may help to understand why .bashrc
    #
    # Extracting because embedded here requires complex escape with nix multiline.
    initExtra =
      ''
        # https://github.com/starship/starship/blob/0d98c4c0b7999f5a8bd6e7db68fd27b0696b3bef/docs/uk-UA/advanced-config/README.md#change-window-title
        function set_win_title() {
        	echo -ne "\033]0; $(${lib.getBin pkgs.coreutils}/bin/basename "$PWD") \007"
        }
        # shellcheck disable=SC2034
        starship_precmd_user_func="set_win_title"

        source "${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh"
        source "${pkgs.podman}/share/bash-completion/completions/podman"
        source "${pkgs.kubectl}/share/bash-completion/completions/kubectl.bash"
        source "${pkgs.kind}/share/bash-completion/completions/kind.bash"
        source "${pkgs.zellij}/share/bash-completion/completions/zellij.bash"

        # Adding only in devshell is not enough
        source "${edge-pkgs.cargo-make}/share/bash-completion/completions/makers-completion.bash"

        source "${../dependencies/dprint/completions.bash}"

        # Disable `Ctrl + S(no output tty)`
        ${lib.getBin pkgs.coreutils}/bin/stty stop undef

        source "${homemade-pkgs.posix_shared_functions}"

        if [ 'linux' = "$TERM" ]; then
          # Avoid Tofu
          export LANG=C
          export STARSHIP_CONFIG="${pkgs.starship}/share/starship/presets/plain-text-symbols.toml"

          disable_blinking_cursor
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
