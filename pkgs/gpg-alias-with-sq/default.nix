{ pkgs, edge-pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "gpg"; # This will be the alias.
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = [ edge-pkgs.sequoia-chameleon-gnupg ];
  meta.description = "See GH-830";
}
