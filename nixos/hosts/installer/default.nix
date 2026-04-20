{
  modulesPath,
  pkgs,
  lib,
  outputs,
  ...
}:

let
  mkUserRaw = import ../../desktop/mkUser.nix { inherit lib; };
  # Get only the groups from the helper
  userDefaults = mkUserRaw { };
in
{
  imports = [
    # Strictly follow the "Nix Flakes" section of the Wiki
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")

    # Project specific desktop tools/settings
    outputs.nixosModules.desktop
  ];

  # Wiki "Building faster" section
  isoImage.squashfsCompression = "gzip -Xcompression-level 1";

  # Wiki "SSH" section: Enable SSH and set keys for root
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
  users.users.root.openssh.authorizedKeys.keys = import ../../../config/ssh/keys.nix;

  # Project specific requirement: Use sudo-rs (project standard) without password
  # Explicitly force sudo-rs to resolve conflict with standard sudo in the ISO profile
  security.sudo.enable = lib.mkForce false;
  security.sudo-rs = {
    enable = lib.mkForce true;
    wheelNeedsPassword = false;
  };

  # Complement the existing 'nixos' user with required groups and keys.
  # Use mkAfter to ensure we add to the groups defined in the ISO profile (e.g., wheel, video).
  users.users.nixos = {
    extraGroups = lib.mkAfter userDefaults.extraGroups;
    openssh.authorizedKeys.keys = import ../../../config/ssh/keys.nix;
  };

  # Apply home-manager settings to 'nixos' user for ephemeral desktop experience
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.nixos = {
      imports = [
        ../../../home-manager/ephemeral.nix
        ../../../home-manager/nixos-desktop-set.nix
        { home.username = "nixos"; }
      ];
    };
    extraSpecialArgs = { inherit pkgs; };
  };

  system.stateVersion = "25.11";
}
