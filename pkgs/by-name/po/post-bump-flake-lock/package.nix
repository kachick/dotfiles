{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "post-bump-flake-lock";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    flake-edit
    dprint
    nix
    local.bump_gomod
  ];
  meta = {
    description = "Deduplicate transitive flake inputs, format, relock, and update Go packages after updating flake.lock";
  };
}
