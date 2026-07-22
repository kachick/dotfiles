{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "walk";
  text = builtins.readFile ./walk.bash;
  runtimeInputs = with pkgs; [
    fzf
    fd
    local.preview
  ];
  meta = {
    description = "Fuzzy finder for file path";
  };
}
