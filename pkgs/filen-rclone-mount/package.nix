{ pkgs, lib, ... }:
pkgs.writeShellApplication rec {
  name = "filen-rclone-mount";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    coreutils # `mktemp`
    my.filen-rclone
  ];
  meta = {
    description = "Mount filen-rclone to my usual directory";
    # Didn't work on Darwin. It might work when disabling --daemon or replacing the default NFS with FUSE. However, I'm very tired to consider Darwin.
    platforms = lib.platforms.linux;
  };
}
