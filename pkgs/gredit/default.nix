{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "gredit";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    helix # Cannot be replaced with $EDITOR, because of dependent helix cli options
    ripgrep # https://github.com/BurntSushi/ripgrep/issues/1877#issuecomment-850557751
    coreutils # `cut`
    findutils # `xargs`
    ncurses # `reset` for broken terminal after killing xargs
    # TODO: Add zellij layouts to easy killing xargs with special pane
  ];
}
