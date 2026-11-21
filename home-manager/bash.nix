{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.starship.enableBashIntegration = true;
  programs.zoxide.enableBashIntegration = true;
  programs.fzf.enableBashIntegration = false; # GH-1192: Don't enable fzf integrations, they make shell startup slower. Load only key-bindings if required.
  programs.zellij.enableBashIntegration = false; # Intentionally disabled for keeping stable bash

  # Used only in bash - https://unix.stackexchange.com/a/689403
  # https://github.com/nix-community/home-manager/blob/release-26.05/modules/programs/readline.nix
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

  # https://github.com/nix-community/home-manager/blob/release-26.05/modules/programs/bash.nix
  programs.bash = {
    enable = true;

    # Keep the default as possible
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
      "export"
      "exit"
    ];

    # For interactive shells. In .bashrc and after early return
    # https://github.com/nix-community/home-manager/blob/release-26.05/modules/programs/bash.nix#L271
    # And https://techracho.bpsinc.jp/hachi8833/2021_07_08/66396 may help to understand why .bashrc
    #
    # Extracting because embedded here requires complex escape with nix multiline.
    #
    # Don't put shell delegation code into early phase than interactive check such as profileExtra and bashrcExtra , it blocks applying home.file on NixOS. See GH-680 for details
    # There is no ideal option in home-manager bash module for realizing first entry of the interactive shell. https://github.com/nix-community/home-manager/blob/f463902a3f03e15af658e48bcc60b39188ddf734/modules/programs/bash.nix#L227-L240
    # However initExtra is still better option than profileExtra.
    initExtra = lib.mkMerge [
      (
        builtins.readFile ./delegate_to_zsh.bash
        + ''
          delegate_to_zsh "${lib.getExe pkgs.zsh}" "${lib.getExe' pkgs.procps "ps"}"
          unset -f delegate_to_zsh

          # Workaround for issues likely https://github.com/reubeno/brush/issues/380
          # Don't use the "command -v", it makes it much slower. (+50ms on bash). Prefer https://github.com/reubeno/brush/pull/531 instead
          if [[ -z "''${BRUSH_VERSION+this_shell_is_brush_not_the_bash}" ]]; then
          	# original fzf providing key-bindigns also makes some warnings in brush
          	source "${pkgs.fzf}/share/fzf/key-bindings.bash" # Don't load completions. It makes shell startup much slower
          fi

          # Disable `Ctrl + S(no output tty)`
          ${lib.getExe' pkgs.coreutils "stty"} stop undef

          source "${pkgs.local.posix_shared_functions}"

          # https://github.com/starship/starship/blob/0d98c4c0b7999f5a8bd6e7db68fd27b0696b3bef/docs/uk-UA/advanced-config/README.md#change-window-title
          # shellcheck disable=SC2034
          starship_precmd_user_func="set_win_title"

          # To prefer ISO 8601 format. See https://unix.stackexchange.com/questions/62316/why-is-there-no-euro-english-locale
          # And don't set this in home-manager's sessionVariables. It causes confusing behavior or bugs when using GNOME (or any other DE)
          export LC_TIME='en_DK.UTF-8'

          if [ 'linux' = "$TERM" ]; then
            adjust_to_linux_vt
          fi
        ''
        + builtins.readFile ./initExtra.bash
      )
      (lib.mkAfter ''
        # brush skips ~/.brushrc in login shells, and Home Manager's .bash_profile only sources ~/.bashrc.
        # https://brush.sh/how-tos/configuration/#which-files-are-read
        if [[ -n "''${BRUSH_VERSION+this_shell_is_brush_not_the_bash}" ]] && shopt -q login_shell && [[ -r ~/.brushrc ]]; then
          source ~/.brushrc
        fi
      '')
    ];

    logoutExtra = ''
      # when leaving the console clear the screen to increase privacy

      if [ "$SHLVL" = 1 ]; then
        [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
      fi
    '';
  };
}
