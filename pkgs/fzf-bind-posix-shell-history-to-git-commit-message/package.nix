{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "fzf-bind-posix-shell-history-to-git-commit-message";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    my.safe_quote_backtik
    git
    fzf
    nushell
  ];
  meta = {
    description = "Used in git alias";
  };
}
