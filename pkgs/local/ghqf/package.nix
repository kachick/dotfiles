{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "ghqf";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    ghq
    fzf
    eza
  ];
  meta = {
    description = "ghq + fzf result";
  };
}
