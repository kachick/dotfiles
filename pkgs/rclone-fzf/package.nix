{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "rclone-fzf";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    fzf
    coreutils # `mktemp`
    rclone
    my.rclone-list-mounted
  ];
}
