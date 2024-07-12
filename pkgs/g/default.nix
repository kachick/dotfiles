{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "g";
  runtimeInputs = with pkgs; [ git ];
  text = ''
    git "$@"
  '';
}
