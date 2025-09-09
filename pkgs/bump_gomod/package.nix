{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "bump_gomod";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    git
    go_1_25
    gnugrep
    findutils # `xargs`
    nix-update
  ];
  meta = {
    description = "Update go.mod with method of https://github.com/kachick/times_kachick/issues/265";
  };
}
