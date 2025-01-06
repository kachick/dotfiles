{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "rg-fzf";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    fzf
    ripgrep
    bat
    coreutils # `cat`
    # unnecessary to specify an editor. Both helix and micro supports `exe {1}:{2}:{3}` style.
  ];
}
