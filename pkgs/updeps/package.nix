{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "updeps";
  text = builtins.readFile ./${name}.bash;
  # Do no include "nix" in runtimeInputs: https://github.com/NixOS/nix/issues/5473
  meta = {
    description = "Run update commands except NixOS";
  };
}
