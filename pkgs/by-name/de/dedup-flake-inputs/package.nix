{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "dedup-flake-inputs";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    flake-edit
    dprint
    nix
  ];
  meta = {
    description = "Deduplicate transitive flake inputs with flake-edit, format flake.nix, and relock";
  };
}
