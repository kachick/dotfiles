{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "p";
  runtimeInputs = with pkgs; [
    nix
    zsh
  ];
  text = builtins.readFile ./${name}.bash;
}
