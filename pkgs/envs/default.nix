{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "envs";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    coreutils # `env`, `sort`
    fzf
  ];
}
