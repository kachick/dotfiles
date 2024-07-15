{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "bump_completions";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    git
    dprint
  ];
}
