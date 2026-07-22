{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "ghqf";
  text = builtins.readFile ./ghqf.bash;
  runtimeInputs = with pkgs; [
    ghq
    fzf
    eza
  ];
  meta = {
    description = "ghq + fzf result";
  };
}
