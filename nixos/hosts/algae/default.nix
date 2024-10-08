{ ... }:

{
  networking.hostName = "algae";

  imports = [
    ../../configuration.nix
    ../../hardware.nix
    ../../desktop

    ./hardware-configuration.nix
  ];

  # Apply better fonts for non X consoles
  # https://github.com/NixOS/nixpkgs/issues/219239
  boot.initrd.kernelModules = [ "amdgpu" ];

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 20;
  };

  services.xserver.videoDrivers = [ "amdgpu" ];
}
