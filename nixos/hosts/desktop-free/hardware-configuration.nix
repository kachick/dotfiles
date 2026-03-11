{
  lib,
  ...
}:

{
  # Absolute minimum hardware configuration for CI evaluation/build verification.
  # This file system configuration is dummy for CI purpose.
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/sda2";
    fsType = "vfat";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
