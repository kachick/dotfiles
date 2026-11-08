{
  outputs,
  lib,
  ...
}:

{
  # dev-headless is a generic NixOS configuration for headless development.
  # This host is primarily used in CI to:
  # 1. Verify the headless configuration set (outputs.nixosModules.dev-headless)
  # 2. Ensure the system evaluates and builds correctly without desktop/unfree packages.
  # 3. Generate binary caches for headless development tools and base system.
  networking.hostName = "dev-headless";

  imports = [
    outputs.nixosModules.dev-headless
  ];

  # Minimum dummy file system configuration for CI build verification
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/sda2";
    fsType = "vfat";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "26.05";
  boot.loader.systemd-boot.enable = true;
}
