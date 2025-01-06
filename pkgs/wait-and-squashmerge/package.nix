{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "wait-and-squashmerge";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [ gh ];
  meta = {
    description = "Squash merge a PR after passed all checks";
  };
}
