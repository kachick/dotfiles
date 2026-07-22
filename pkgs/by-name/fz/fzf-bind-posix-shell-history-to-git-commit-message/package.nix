{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "fzf-bind-posix-shell-history-to-git-commit-message";
  text = builtins.readFile ./fzf-bind-posix-shell-history-to-git-commit-message.bash;
  runtimeInputs = with pkgs; [
    local.safe_quote_backtik
    gitMinimal
    fzf
    nushell
  ];
  meta = {
    description = "Used in git alias";
  };
}
