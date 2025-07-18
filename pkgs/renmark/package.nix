{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "renmark";
  text = builtins.readFile ./${name}.bash;
  # Old candidates
  # - glow, pandoc, inlyne, chawan built-in markdown renderer, mdcat, gh-markdown-preview, Lynx, w3m
  #
  # After several candidates, I think this combination is the best for now.
  runtimeInputs = with pkgs; [
    chawan
    comrak
  ];
  meta.description = "RENder MARkdown in terminal. See GH-740";
}
