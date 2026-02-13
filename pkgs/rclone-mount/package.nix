{ pkgs, lib, ... }:
pkgs.writeShellApplication rec {
  name = "rclone-mount";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    coreutils # `mktemp`
    util-linux # `mountpoint` (Not available on Darwin)
    patched.rclone
  ];
  meta = {
    description = "Mount rclone to my usual directory";
    # Didn't work on Darwin. It might work when disabling --daemon or replacing the default NFS with FUSE. However, I'm very tired to consider Darwin.
    # If supporting Darwin in the future, keep in mind that `mountpoint` command is not available.
    platforms = lib.platforms.linux;
  };
}
