{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "bench_shells";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    hyperfine
    zsh
    bashInteractive
    fish
  ];
}
