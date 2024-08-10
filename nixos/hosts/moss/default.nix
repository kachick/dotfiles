{ inputs, ... }:

{
  networking.hostName = "moss";

  imports = [
    ../../configuration.nix
    ../../gui.nix

    ./hardware-configuration.nix
    ./fingerprint.nix

    inputs.xremap-flake.nixosModules.default
    ../../xremap.nix
  ];

  # Apply better fonts for non X consoles
  # https://github.com/NixOS/nixpkgs/issues/219239
  boot.initrd.kernelModules = [ "amdgpu" ];

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 42;
  };

  services.xserver.videoDrivers = [ "amdgpu" ];
}
