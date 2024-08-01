{ pkgs, edge-pkgs, ... }:

{
  networking.hostName = "wsl";

  imports = [
    ../../configuration.nix

    # ./hardware-configuration.nix
  ];
}
