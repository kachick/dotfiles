{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "git-log-fzf";
  text = builtins.readFile ./git-log-fzf.bash;
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
