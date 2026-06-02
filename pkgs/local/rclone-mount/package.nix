{ pkgs, lib, ... }:
pkgs.writeShellApplication rec {
  name = "rclone-mount";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    coreutils # `mktemp`
    util-linux # `mountpoint`
    unstable.rclone
  ];
  meta = {
    description = "Mount rclone to my usual directory";
    platforms = lib.platforms.linux;
  };
}
