{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "rclone-fzf";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    fzf
    rclone
    my.rclone-mount
    my.rclone-list-mounted
  ];
}
