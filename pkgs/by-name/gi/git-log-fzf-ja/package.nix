{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "git-log-fzf-ja";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    fzf
    coreutils
    gitMinimal
    gh
    colorized-logs
    bat
    riffdiff
    curl
    local.git-log-simple
    local.git-show-ja
  ];
  meta = {
    description = "Faster git log searcher with asynchronous Japanese translation preview for large repositories";
  };
}
