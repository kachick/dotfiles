{ pkgs, edge-pkgs, ... }:

{
  networking.hostName = "algae";

  imports = [
    ../../configuration.nix
    ../../gui.nix

    ./hardware-configuration.nix
  ];

  # Apply better fonts for non X consoles
  # https://github.com/NixOS/nixpkgs/issues/219239
  boot.initrd.kernelModules = [ "amdgpu" ];

  services.xserver.videoDrivers = [ "amdgpu" ];
}
