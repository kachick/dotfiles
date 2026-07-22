{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "wait-and-squashmerge";
  text = builtins.readFile ./wait-and-squashmerge.bash;
  runtimeInputs = with pkgs; [ gh ];
  meta = {
    description = "Squash merge a PR after passed all checks";
  };
}
