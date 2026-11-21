{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "lat";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    gitMinimal
    local.la
  ];
  meta = {
    description = "ls all and tree";
  };
}
