{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "lat";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = [ pkgs.local.la ];
  meta = {
    description = "ls all and tree";
  };
}
