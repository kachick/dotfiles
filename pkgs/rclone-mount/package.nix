{ pkgs, lib, ... }:
pkgs.writeShellApplication rec {
  name = "rclone-mount";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    coreutils # `mktemp`
    rclone
  ];
  # Didn't work on Darwin. It might work when disabling --daemon or replacing the default NFS with FUSE. However, I'm very tired to consider Darwin.
  meta.platforms = lib.platforms.linux;
}
