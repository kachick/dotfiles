{ pkgs, ... }:

{
  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/programs/fzf.nix
  # https://github.com/junegunn/fzf/blob/master/README.md
  programs.fzf = rec {
    enable = true;

    # https://github.com/junegunn/fzf/blob/d579e335b5aa30e98a2ec046cb782bbb02bc28ad/README.md#respecting-gitignore
    defaultCommand = "${pkgs.fd}/bin/fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";

    defaultOptions = [
      # --walker*: Default file filtering will be changed by this option if FZF_DEFAULT_COMMAND is not set: https://github.com/junegunn/fzf/pull/3649/files
      "--walker-skip '.git,node_modules,.direnv,vendor,dist'"
    ];

    # CTRL+T - such as `pkgs.my.walk`. However, you shouldn't use fzf's `become`. This will be used in shell functions.
    fileWidgetCommand = defaultCommand;
    fileWidgetOptions = [
      "--preview '${pkgs.bat}/bin/bat --color=always {}'"
      "--preview-window '~3'"
      ''
        --bind 'enter:execute("$EDITOR" {})'
      ''
    ];

    # ALT-C
    changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d --hidden --exclude .git";
    changeDirWidgetOptions = [ "--preview '${pkgs.eza}/bin/eza --color=always --tree {} | head -200'" ];

    colors = {
      # See #295 for the detail
      "bg+" = "#005f5f";
    };
  };
}
