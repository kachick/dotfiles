{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "wait-and-squashmerge";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    gh
    micro
  ];
}
