{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "bump_gomod";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    git
    unstable.go_1_24
    gnugrep
    findutils # `xargs`
  ];
  meta = {
    description = "Update go.mod with method of https://github.com/kachick/times_kachick/issues/265";
  };
}
