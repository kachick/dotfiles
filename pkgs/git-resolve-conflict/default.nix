{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "git-resolve-conflict";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    git # https://superuser.com/questions/321310/how-to-view-only-the-unmerged-files-in-git-after-a-merge-failure#comment2723241_682132
    helix # Cannot be replaced with $EDITOR, because of dependent helix cli options
    ripgrep # https://github.com/BurntSushi/ripgrep/issues/1877#issuecomment-850557751
    coreutils # `cut`
    findutils # `xargs`
    ncurses # `reset` for broken terminal after killing xargs
  ];
}
