{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "tree-diff";
  text = builtins.readFile ./tree-diff.bash;
  runtimeInputs = with pkgs; [
    tree
    gitMinimal
    nushell # Better unicode handling than bash and sed
  ];
  meta = {
    description = "Compare and visualize file tree differences across two directories";
  };
}
