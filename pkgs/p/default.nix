{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "p";
  runtimeInputs = with pkgs; [ nix ];
  text = builtins.readFile ./${name}.bash;
}
