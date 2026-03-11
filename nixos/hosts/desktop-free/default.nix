{
  outputs,
  ...
}:

{
  # desktop-free is a generic NixOS configuration that contains only free software.
  # This host is primarily used in CI to:
  # 1. Verify the basic desktop configuration set (outputs.nixosModules.desktop)
  # 2. Ensure the system evaluates and builds correctly without unfree packages.
  # 3. Generate binary caches that are safe to distribute publicly without licensing issues.
  networking.hostName = "desktop-free";

  imports = [
    outputs.nixosModules.desktop
    outputs.nixosModules.hardware
    ../../desktop/kachick.nix

    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.11";

  boot.loader.systemd-boot.enable = true;
}
