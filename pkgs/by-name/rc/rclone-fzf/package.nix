{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "rclone-fzf";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    fzf
    unstable.rclone
    local.rclone-mount
    local.rclone-list-mounted
  ];
  meta = {
    description = "List and operate rclone remotes";
  };
}
