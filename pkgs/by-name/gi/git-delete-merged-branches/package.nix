{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "git-delete-merged-branches";
  text = builtins.readFile ./git-delete-merged-branches.bash;
  runtimeInputs = with pkgs; [
    gitMinimal
    coreutils
    findutils
  ];
  meta = {
    description = "Remove merged branches from local";
  };
}
