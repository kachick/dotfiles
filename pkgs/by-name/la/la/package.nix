{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "la";
  text = builtins.readFile ./la.bash;
  runtimeInputs = with pkgs; [ eza ];
  meta = {
    description = "ls all";
  };
}
