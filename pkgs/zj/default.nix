{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "zj";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    coreutils
    zellij
  ];
}
