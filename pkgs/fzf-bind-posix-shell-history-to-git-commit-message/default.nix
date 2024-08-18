{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "fzf-bind-posix-shell-history-to-git-commit-message";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    (import ../safe_quote_backtik { inherit pkgs; })
    git
    fzf
    go_1_22
  ];
  runtimeEnv = {
    GO_SCRIPT_TO_NORMALIZE = "${./main.go}";
  };
  meta = {
    description = "Used in git alias";
  };
}
