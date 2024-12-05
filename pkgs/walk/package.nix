{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "walk";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    fzf
    fd
    my.preview
  ];
}
