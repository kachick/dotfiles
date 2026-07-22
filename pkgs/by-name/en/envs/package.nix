{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "envs";
  text = builtins.readFile ./envs.bash;
  runtimeInputs = with pkgs; [
    coreutils # `printenv`
    television
  ];
  meta = {
    description = "List environment variables";
  };
}
