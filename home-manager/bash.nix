{ config, lib, pkgs, ... }:

{
  programs.starship.enableBashIntegration = true;
  programs.direnv.enableBashIntegration = true;
  programs.zoxide.enableBashIntegration = true;
  programs.fzf.enableBashIntegration = true;
  programs.rtx.enableBashIntegration = true;
  # Intentionally disabled for keeping stable bash
  programs.zellij.enableBashIntegration = false;

  # Used only in bash - https://unix.stackexchange.com/a/689403
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/readline.nix
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

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/bash.nix
  programs.bash = {
    enable = true;

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
    historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
    # NOTE: I didn't check it should have different globs as zsh or not, at least the sepelator is not same.
    historyIgnore = [ "cd" "pushd" "popd" "z" "ls" "ll" "la" "rm" "rmdir" "git show" "exit" ];

    # Extracting because embedded here requires complex escape with nix multiline.
    initExtra = ''
      # https://github.com/starship/starship/blob/0d98c4c0b7999f5a8bd6e7db68fd27b0696b3bef/docs/uk-UA/advanced-config/README.md#change-window-title
      function set_win_title() {
      	echo -ne "\033]0; $(${lib.getBin pkgs.coreutils}/bin/basename "$PWD") \007"
      }
      # shellcheck disable=SC2034
      starship_precmd_user_func="set_win_title"

      source "${../dependencies/dprint/completions.bash}"
    '' + builtins.readFile ./initExtra.bash;

    logoutExtra = ''
      # when leaving the console clear the screen to increase privacy

      if [ "$SHLVL" = 1 ]; then
        [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
      fi
    '';
  };
}
