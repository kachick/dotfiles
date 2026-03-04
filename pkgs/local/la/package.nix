{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "la";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [ eza ];
  meta = {
    description = "ls all";
  };
}
