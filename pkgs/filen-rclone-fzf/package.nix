{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "filen-rclone-fzf";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    fzf
    my.filen-rclone
    my.filen-rclone-mount
    # my.rclone-list-mounted # Don't use this. Only support original rclone.
  ];
  meta = {
    description = "List and operate filen-rclone remotes";
  };
}
