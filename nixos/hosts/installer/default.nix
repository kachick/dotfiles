{
  modulesPath,
  pkgs,
  lib,
  outputs,
  ...
}:

let
  mkUser = import ../../desktop/mkUser.nix { inherit lib; };
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

  # Set up the 'nixos' user with mkUser to ensure correct groups (e.g. uinput for kanata)
  users.users.nixos = mkUser {
    description = "NixOS Live User";
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
