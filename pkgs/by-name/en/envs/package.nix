{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "envs";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    coreutils # `printenv`
    television
  ];
  meta = {
    description = "List environment variables";
  };
}
