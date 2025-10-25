{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "check_nixf";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    nixf-diagnose
    gitMinimal
    findutils # `xargs`
  ];
  meta = {
    description = "Wrapper for nixf-diagnose which does not have dir walker";
  };
}
