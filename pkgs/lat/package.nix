{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "lat";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = [ (import ../la/package.nix { inherit pkgs; }) ];
}
