{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "rclone-mount";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    coreutils # `mktemp`
    rclone
  ];
}
