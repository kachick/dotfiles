{ pkgs, edge-pkgs, ... }:

{
  networking.hostName = "algae";

  imports = [
    ../../configuration.nix
    ../../gui.nix

    ./hardware-configuration.nix
  ];
}
