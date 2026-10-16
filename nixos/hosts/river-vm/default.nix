{
  lib,
  pkgs,
  outputs,
  ...
}:

{
  networking.hostName = "river-vm";

  imports = [
    outputs.nixosModules.desktop
    ../../desktop/kachick.nix
    ./hardware-configuration.nix
  ];

  system.stateVersion = "26.05";

  # Disable GDM and GNOME from desktop module to run river instead
  services.displayManager.gdm.enable = lib.mkForce false;
  services.desktopManager.gnome.enable = lib.mkForce false;

  # Enable river dynamic tiling Wayland compositor
  programs.river-classic.enable = true;

  # Set initial hashed password so the account is active and passwordless sudo works
  users.users.kachick.initialHashedPassword = "$6$5l5GNCXAzGI1KnSW$3Tfj6d6tBOj7pHIXe90X47tVEdOxFiACOCjuPOK1bEuFxHgbXhutjWy2r7HMcreedRsUj7kWBlCNY32jqo5v8/";

  # Auto-login directly into river session using greetd
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.river-classic}/bin/river -log-level debug";
        user = "kachick";
      };
      default_session = {
        command = "${pkgs.river-classic}/bin/river -log-level debug";
        user = "kachick";
      };
    };
  };

  # Allow passwordless sudo for automatic poweroff in headless test scripts
  security.sudo.wheelNeedsPassword = false;

  home-manager.users.kachick = {
    imports = [
      ../../../home-manager/river.nix
    ];
  };

  # QEMU VM specifications
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 4096;
      cores = 4;
      resolution = {
        x = 1280;
        y = 800;
      };
    };
  };
}
