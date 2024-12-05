{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "p";
  text = builtins.readFile ./${name}.bash;
}
