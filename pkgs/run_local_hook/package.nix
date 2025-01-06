{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "run_local_hook";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    git
    coreutils # `cat`
  ];
  meta = {
    description = "GH-545. Run local git hook from global hook";
  };
}
