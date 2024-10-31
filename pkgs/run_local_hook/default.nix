{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "run_local_hook";
  text = builtins.readFile ./${name}.bash;
  meta.description = "GH-545";
  runtimeInputs = with pkgs; [
    git
    coreutils # `cat`
  ];
}
