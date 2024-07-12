{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "todo";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    git
    fzf
    micro
    bat
  ];
  meta = {
    description = "List todo family";
  };
}
