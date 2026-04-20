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

  # Project specific requirement: Standard sudo without password for the live environment
  security.sudo.enable = lib.mkForce true;
  security.sudo-rs.enable = lib.mkForce false;
  security.sudo.wheelNeedsPassword = lib.mkForce false;

  # Project specific requirement: Apply HM to the default 'nixos' user
  users.users.nixos.openssh.authorizedKeys.keys = import ../../../config/ssh/keys.nix;
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nixos = {
      imports = [
        ../../../home-manager/common.nix
        ../../../home-manager/linux.nix
        { targets.genericLinux.enable = false; }
        ../../../home-manager/systemd.nix
        ../../../home-manager/desktop.nix
        ../../../home-manager/firefox.nix
      ];
    };
    extraSpecialArgs = { inherit pkgs; };
  };

  system.stateVersion = "25.11";
}
