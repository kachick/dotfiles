{
  modulesPath,
  lib,
  pkgs,
  outputs,
  ...
}:

let
  mkUser = import ../../desktop/mkUser.nix { inherit lib; };

  findAndLoopIso = pkgs.writeShellApplication {
    name = "find-and-loop-iso";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.systemd
      pkgs.util-linux
    ];
    text = builtins.readFile ./find-and-loop-iso.bash;
  };

  startLlamaPlamo = pkgs.writeShellApplication {
    name = "start-llama-plamo";
    runtimeInputs = [
      pkgs.llama-cpp
    ];
    text = builtins.readFile ./start-llama-plamo.bash;
  };
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

  # Support loopback ISO boot (e.g. MultiOS-USB) under systemd initrd.
  # Upstream nixpkgs passes `findiso=` from GRUB loopback.cfg, but stage 1 does
  # not yet attach the ISO file automatically or bundle exfat in initrd.
  boot.initrd = {
    kernelModules = [ "loop" ];
    supportedFilesystems = [
      "exfat"
      "ext4"
    ];
    systemd = {
      storePaths = [ findAndLoopIso ];
      services.loopback-iso-finder = {
        description = "Loop-mount ISO file from GRUB findiso";
        wantedBy = [ "initrd.target" ];
        before = [
          "sysroot.mount"
          "sysroot-iso.mount"
        ];
        after = [ "systemd-udevd.service" ];
        unitConfig = {
          DefaultDependencies = false;
          # Skip entirely on normal direct-burn ISO or VM boots.
          ConditionKernelCommandLine = "findiso";
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = lib.getExe findAndLoopIso;
        };
      };
    };
  };

  # Apply home-manager settings to 'nixos' user for ephemeral desktop experience
  home-manager.users.nixos = {
    imports = [
      ../../../home-manager/ephemeral.nix
      ../../../home-manager/nixos-desktop-base.nix
      {
        home.username = "nixos";
        # Avoid downloading a large GGUF model into tmpfs on Live CD boot,
        # while still loading a pre-placed local GGUF from the loopback USB host.
        systemd.user.services.llama-plamo = {
          Service.ExecStart = lib.mkForce (lib.getExe startLlamaPlamo);
          Install.WantedBy = lib.mkForce [ ];
        };
        systemd.user.services.llama-plamo-offline-autostart = {
          Unit = {
            Description = "Auto-start llama-plamo when a local GGUF exists on the Live USB";
            ConditionPathExistsGlob = [
              "|/run/loopback-host/models/*plamo-3-translate-0.8b*.gguf"
              "|/run/loopback-host/*plamo-3-translate-0.8b*.gguf"
            ];
          };
          Service = {
            Type = "oneshot";
            # Trigger via systemctl instead of Unit.Wants because systemd still starts
            # Wanted units even when Condition* evaluates to false.
            ExecStart = "${pkgs.systemd}/bin/systemctl --user start --no-block llama-plamo.service";
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
        };
      }
    ];
  };

  system.stateVersion = "26.05";

  # Disable to avoid SC2174 for `mkdir -m 0700 -p /root/.nix-defexpr`
  # Revisit once using 26.11 or later
  systemd.enableStrictShellChecks = lib.mkForce false;
}
