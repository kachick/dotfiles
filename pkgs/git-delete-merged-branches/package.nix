{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "git-delete-merged-branches";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    git
    coreutils
    findutils
  ];
  meta = {
    description = "Remove merged branches from local";
  };
}
