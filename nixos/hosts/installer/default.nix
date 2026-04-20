{
  modulesPath,
  pkgs,
  lib,
  outputs,
  ...
}:

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

  # Safe way to add 'nixos' user to groups without overwriting the base user definition
  users.groups = {
    uinput.members = [ "nixos" ];
    input.members = [ "nixos" ];
    scanner.members = [ "nixos" ];
    lp.members = [ "nixos" ];
  };

  # Ensure the keys are set without overwriting the user definition
  users.users.nixos.openssh.authorizedKeys.keys = import ../../../config/ssh/keys.nix;

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
