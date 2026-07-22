{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "git-log-fzf";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    fzf
    coreutils
    gitMinimal
    gh
    colorized-logs
    bat
    riffdiff
    local.git-log-simple
  ];
  meta = {
    description = "Faster git log searcher for large repositories(e.g NixOS/nixpkgs)";
  };
}
