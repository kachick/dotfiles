{
  lib,
  ...
}:

{
  # Minimum hardware configuration for VM evaluation/build.
  # The qemu-vm module replaces these with virtual disks and 9p shares.
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
