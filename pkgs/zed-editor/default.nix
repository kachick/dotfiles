{ pkgs, edge-pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "zed-editor";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = [ edge-pkgs.zed-editor ];
  meta.description = "Make shorter command again even through applied https://github.com/NixOS/nixpkgs/pull/344193";
}
