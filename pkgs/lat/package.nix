{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "lat";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = [ pkgs.my.la ];
}
