{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "walk";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    fzf
    fd
    local.preview
  ];
  meta = {
    description = "Fuzzy finder for file path";
  };
}
