{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "todo";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    git # Don't use `gitMinimal` here. PCRE support is required
    fzf
    bat
  ];
  meta = {
    description = "List todo family";
  };
}
