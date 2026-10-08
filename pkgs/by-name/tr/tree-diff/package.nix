{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "tree-diff";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    tree
    gitMinimal
    nushell # Better unicode handling than bash and sed
  ];
  meta = {
    description = "Compare and visualize file tree differences across two directories";
  };
}
