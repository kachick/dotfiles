{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "git-log-simple";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [ git ];
  meta = {
    description = "Beautify git log with keeping the lightweight";
  };
}
