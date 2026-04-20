{
  modulesPath,
  pkgs,
  lib,
  outputs,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")

    outputs.nixosModules.desktop
  ];

  system.stateVersion = "25.11";

  # Use standard sudo for the installer environment
  security.sudo.enable = lib.mkForce true;
  security.sudo-rs.enable = lib.mkForce false;

  # Ensure the live 'nixos' user can use sudo without a password
  # Note: installation-cd-minimal.nix usually sets this up via profiles/installation-device.nix
  # but we force it here to be certain given the common config's sudo-rs settings.
  security.sudo.wheelNeedsPassword = false;

  # Set up authorized keys for the default 'nixos' user
  users.users.nixos.openssh.authorizedKeys.keys = import ../../../config/ssh/keys.nix;

  # Apply home-manager settings to the live 'nixos' user
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nixos = {
      imports = [
        ../../../home-manager/kachick.nix
        ../../../home-manager/linux.nix
        { targets.genericLinux.enable = false; }
        ../../../home-manager/systemd.nix
        ../../../home-manager/desktop.nix
        ../../../home-manager/firefox.nix
      ];
    };
    extraSpecialArgs = { inherit pkgs; };
  };
}
