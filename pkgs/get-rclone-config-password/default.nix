{ edge-pkgs, pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "get-rclone-config-password";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = [ edge-pkgs.goldwarden ];
}
