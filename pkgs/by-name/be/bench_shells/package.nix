{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "bench_shells";
  text = builtins.readFile ./bench_shells.bash;
  runtimeInputs = with pkgs; [
    hyperfine
    zsh
    bashInteractive
    unstable.brush
    nushell
  ];
  meta = {
    description = "Measure speed of shells with the interactive mode";
  };
}
