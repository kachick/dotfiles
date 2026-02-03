{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "rclone-fzf";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    fzf
    patched.rclone
    my.rclone-mount
    my.rclone-list-mounted
  ];
  meta = {
    description = "List and operate rclone remotes";
  };
}
