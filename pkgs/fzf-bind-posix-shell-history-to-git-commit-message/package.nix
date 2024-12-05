{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "fzf-bind-posix-shell-history-to-git-commit-message";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    (import ../safe_quote_backtik/package.nix { inherit pkgs; })
    git
    fzf
    ruby_3_3
  ];
  meta = {
    description = "Used in git alias";
  };
}
