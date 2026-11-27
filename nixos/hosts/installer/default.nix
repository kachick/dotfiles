{
  modulesPath,
  lib,
  pkgs,
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

    # Project specific desktop base (excludes VM stack and daily apps) and keyboard hwdb remaps
    outputs.nixosModules.desktop-base
    outputs.nixosModules.hardware
  ];

  programs.command-not-found.enable = false; # TODO: Reconsider once https://github.com/NixOS/nixpkgs/pull/512785 has available

  # Match NixOS 26.11 default recommendation and prevent evaluation warning
  boot.zfs.forceImportRoot = false;

  # Wiki "Building faster" section
  isoImage.squashfsCompression = "gzip -Xcompression-level 1";

  # Wiki "SSH" section: Enable SSH for the live user (root SSH stays disabled via PermitRootLogin = "no")
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];

  # Live user has no password, so auto-login into the desktop session on boot.
  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

  # Project specific requirement: Use sudo-rs (project standard) without password
  # Explicitly force sudo-rs to resolve conflict with standard sudo in the ISO profile
  security.sudo.enable = lib.mkForce false;
  security.sudo-rs = {
    enable = lib.mkForce true;
    wheelNeedsPassword = false;
  };

  # Set up the 'nixos' user using the project's standard mkUser helper.
  # This ensures consistency with owner/ephemeral users, including group memberships like uinput.
  users.users.nixos = mkUser {
    description = "NixOS Live User";
    extraGroups = [
      "wheel"
    ];
    openssh.authorizedKeys.keys = import ../../../config/ssh/keys.nix;
  };

  # Allow the live user to manage Tailscale (including tailscale-systray) without sudo.
  services.tailscale.extraSetFlags = [ "--operator=nixos" ];

  environment.systemPackages = with pkgs; [
    # Keep explicitly so GUI disk/LUKS management stays available even if the desktop environment changes.
    gnome-disk-utility
    tpm2-tools
  ];

  # Exclude test containerd daemon from the recovery Live CD.
  virtualisation.containerd.enable = lib.mkForce false;

  # Apply home-manager settings to 'nixos' user for ephemeral desktop experience
  home-manager.users.nixos = {
    imports = [
      ../../../home-manager/ephemeral.nix
      ../../../home-manager/nixos-desktop-base.nix
      {
        home.username = "nixos";
        # Avoid downloading a large GGUF model into tmpfs on Live CD boot.
        systemd.user.services.llama-plamo.Install.WantedBy = lib.mkForce [ ];
      }
    ];
  };

  system.stateVersion = "26.05";

  # Disable to avoid SC2174 for `mkdir -m 0700 -p /root/.nix-defexpr`
  # Revisit once using 26.11 or later
  systemd.enableStrictShellChecks = lib.mkForce false;
}
