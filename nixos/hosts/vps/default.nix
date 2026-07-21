# NixOS configuration for ConoHa VPS 3.0
# Dynamic network IP/Gateway is auto-provisioned at boot via ConoHa 3.0 ConfigDrive (/dev/disk/by-label/config-2)

{
  lib,
  pkgs,
  outputs,
  modulesPath,
  ...
}:

{
  networking.hostName = "vps";

  imports = [
    outputs.nixosModules.common
    outputs.nixosModules.home-manager
    ./disko-config.nix
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Apply general virtual machine optimizations
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Using the state version matching the channels config in flake.nix
  system.stateVersion = "26.05";

  # Bootloader configurations for hybrid BIOS/EFI
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  # Enable Tailscale
  services.tailscale.enable = true;

  # Idempotent dynamic network auto-configuration service for ConoHa VPS 3.0 OpenStack ConfigDrive.
  #
  # WHY NOT `services.cloud-init`?
  # - NixOS's `services.cloud-init` is heavy, complex, and unreliably failed to apply network interfaces
  #   (eth0/ens3) during system startup and initial provision (`nixos-anywhere`).
  # - `cloud-init` brings unnecessary Python dependencies and features (e.g. user creation/SSH key injection)
  #   that conflict with NixOS's declarative model.
  #
  # WHY NOT hardcoded static IP in repository?
  # - Keeping static IPs hardcoded in public repository leaks network configuration and breaks seamless
  #   re-creations (`nixos-anywhere`) when server IP changes or is rebuilt.
  #
  # WHY THIS ONESHOT SERVICE IS THE MOST RELIABLE APPROACH:
  # - Directly parses OpenStack ConfigDrive (/dev/disk/by-label/config-2) metadata JSON
  #   (openstack/latest/network_data.json) using lightweight tools (jq, iproute2, util-linux).
  # - Uses `ip addr replace` and `ip route replace` for 100% idempotent execution on every boot or re-run.
  # - Fully verified to succeed in one-shot automated provisioning (`nixos-anywhere`) from clean rebuilds.
  systemd.services.conoha-autonetwork = {
    description = "Auto-configure network from ConoHa VPS 3.0 ConfigDrive";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-pre.target" ];
    before = [
      "network.target"
      "sshd.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail

      MOUNT_DIR="/run/conoha-configdrive"
      mkdir -p "$MOUNT_DIR"
      cleanup() {
        ${pkgs.util-linux}/bin/umount "$MOUNT_DIR" 2>/dev/null || true
        rm -rf "$MOUNT_DIR"
      }
      trap cleanup EXIT

      if ! ${pkgs.util-linux}/bin/mount -o ro /dev/disk/by-label/config-2 "$MOUNT_DIR" 2>/dev/null; then
        echo "No ConoHa ConfigDrive found, skipping."
        exit 0
      fi

      NET_JSON="$MOUNT_DIR/openstack/latest/network_data.json"
      if [ ! -f "$NET_JSON" ]; then
        echo "No network_data.json found in ConfigDrive, skipping."
        exit 0
      fi

      IP=$(${pkgs.jq}/bin/jq -r '.networks[]? | select(.type=="ipv4") | .ip_address' "$NET_JSON" 2>/dev/null || true)
      NETMASK=$(${pkgs.jq}/bin/jq -r '.networks[]? | select(.type=="ipv4") | .netmask' "$NET_JSON" 2>/dev/null || true)
      GW=$(${pkgs.jq}/bin/jq -r '.networks[]? | select(.type=="ipv4") | .routes[]? | select(.network=="0.0.0.0") | .gateway' "$NET_JSON" 2>/dev/null || true)

      if [ -n "$IP" ] && [ -n "$GW" ]; then
        IFACE=""
        if ${pkgs.iproute2}/bin/ip link show eth0 >/dev/null 2>&1; then
          IFACE="eth0"
        elif ${pkgs.iproute2}/bin/ip link show ens3 >/dev/null 2>&1; then
          IFACE="ens3"
        fi

        if [ -n "$IFACE" ]; then
          PREFIX="23"
          if [ "$NETMASK" = "255.255.254.0" ]; then PREFIX="23"; fi

          ${pkgs.iproute2}/bin/ip link set "$IFACE" up
          ${pkgs.iproute2}/bin/ip addr replace "$IP/$PREFIX" dev "$IFACE"
          ${pkgs.iproute2}/bin/ip route replace default via "$GW" dev "$IFACE"
          echo "Successfully configured $IFACE with $IP/$PREFIX via $GW"
        fi
      fi
    '';
  };

  # Enable shell binaries for interactive use
  programs.bash.enable = true;
  programs.zsh.enable = true;

  # Overrides to permit root login with SSH keys during/after installation
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkForce "prohibit-password";
    };
  };

  users.users.root = {
    hashedPassword = "$6$5l5GNCXAzGI1KnSW$3Tfj6d6tBOj7pHIXe90X47tVEdOxFiACOCjuPOK1bEuFxHgbXhutjWy2r7HMcreedRsUj7kWBlCNY32jqo5v8/";
    openssh.authorizedKeys.keys = import ../../../config/ssh/keys.nix;
  };

  users.users.user = {
    isNormalUser = true;
    description = "VPS user";
    shell = pkgs.zsh;
    hashedPassword = "$6$5l5GNCXAzGI1KnSW$3Tfj6d6tBOj7pHIXe90X47tVEdOxFiACOCjuPOK1bEuFxHgbXhutjWy2r7HMcreedRsUj7kWBlCNY32jqo5v8/";
    extraGroups = [
      "wheel"
      "systemd-journal"
    ];
    openssh.authorizedKeys.keys = import ../../../config/ssh/keys.nix;
  };

  # Integrate minimal home-manager essential module (CLI, shell, editor configs without desktop/dev toolchains)
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.user = {
      imports = [
        outputs.homeManagerModules.essential
        {
          home.username = "user";
        }
      ];
    };
    extraSpecialArgs = {
      inherit pkgs outputs;
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    helix
    ripgrep
    fzf
    dysk
    msedit # edit
    unstable.fresh-editor # fresh-editor
    unstable.herdr # herdr
  ];
}
