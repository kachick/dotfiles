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
    # If supporting Darwin again in the future, keep in mind that `mountpoint` command is not available.
    platforms = lib.platforms.linux;
  };
}
