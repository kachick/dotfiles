{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "bench_shells";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    hyperfine
    zsh
    bashInteractive
    nushell
  ];
  meta = {
    description = "Measure speed of shells with the interactive mode";
  };
}
