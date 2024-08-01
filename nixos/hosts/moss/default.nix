{ pkgs, edge-pkgs, ... }:

{
  networking.hostName = "moss";

  imports = [
    ../../configuration.nix
    ../../fingerprint.nix
    ../../gui.nix

    ./hardware-configuration.nix
  ];
}
