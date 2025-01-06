{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "p";
  text = builtins.readFile ./${name}.bash;
  meta = {
    description = "Wrapper for nix-shell";
  };
}
