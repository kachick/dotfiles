{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "todo";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    gitMinimal
    fzf
    bat
  ];
  meta = {
    description = "List todo family";
  };
}
