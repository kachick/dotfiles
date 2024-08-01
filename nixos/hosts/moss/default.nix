{ pkgs, edge-pkgs, ... }:

{
  networking.hostName = "moss";

  imports = [
    ../../configuration.nix
    ../../gui.nix

    ./hardware-configuration.nix
    ./fingerprint.nix
  ];
}
