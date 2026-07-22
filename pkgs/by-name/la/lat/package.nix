{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "lat";
  text = builtins.readFile ./lat.bash;
  runtimeInputs = [ pkgs.local.la ];
  meta = {
    description = "ls all and tree";
  };
}
