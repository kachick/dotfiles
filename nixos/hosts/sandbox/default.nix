{
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:

{
  networking.hostName = "sandbox";

  imports = [
    inputs.microvm.nixosModules.microvm
    outputs.nixosModules.common
    outputs.nixosModules.home-manager
  ];

  system.stateVersion = "26.05";

  # Quiet kernel and initrd boot logs for fast startup
  boot.consoleLogLevel = 3;
  boot.kernelParams = [
    "quiet"
    "systemd.show_status=auto"
  ];

  # Enable OpenSSH for background exec/ssh over localhost port forwarding.
  # Inherits PasswordAuthentication = false and PermitRootLogin = "no" from nixos/configuration.nix.
  # Disable PerSourcePenalties because SLiRP forwards every host connection from 10.0.2.2,
  # so a few preauth probes or auth failures would otherwise lock out all host access.
  services.openssh = {
    enable = true;
    settings.PerSourcePenalties = "no";
  };

  # Disable background daemons not needed in ephemeral sandbox
  services.fail2ban.enable = lib.mkForce false;
  services.logrotate.enable = false;

  # Auto-optimise store does not work with writableStoreOverlay
  nix.optimise.automatic = lib.mkForce false;
  nix.settings.auto-optimise-store = lib.mkForce false;

  microvm = {
    # Using QEMU instead of Cloud-Hypervisor:
    # - Cloud-Hypervisor does not support user-mode SLiRP networking (type = "user"),
    #   requiring host root/TAP privileges.
    # - Cloud-Hypervisor only supports virtiofs shares (no built-in 9p), requiring
    #   a separate host-side virtiofsd daemon.
    # Consider switching if microvm.nix or Cloud-Hypervisor gains unprivileged user networking.
    hypervisor = "qemu";
    mem = 4096;
    vcpu = 4;

    # Share host nix-store, system profile, and repos directory
    shares = [
      {
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        proto = "9p";
        readOnly = true;
      }
      {
        tag = "host-sw";
        source = "/run/current-system/sw";
        mountPoint = "/run/host-system-sw";
        proto = "9p";
        readOnly = true;
      }
      {
        tag = "repos";
        source = "/home/kachick/repos/github.com/kachick";
        mountPoint = "/home/user/repos/github.com/kachick";
        proto = "9p";
      }
    ];

    # Volatile writable overlay for /nix/store
    writableStoreOverlay = "/nix/.rw-store";

    # Avoid dropping socket files into current working directory
    socket = null;

    # Safe rootless user networking (SLiRP)
    interfaces = [
      {
        type = "user";
        id = "net0";
        mac = "02:00:00:01:01:01";
      }
    ];
  };

  # Ephemeral writable overlay for /nix/store backed by tmpfs
  fileSystems."/nix/.rw-store" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "size=2G"
      "mode=0755"
    ];
    neededForBoot = true;
  };

  # Autologin directly to user on serial console after home-manager finishes setup.
  # Use xterm-256color instead of linux because QEMU stdio renders in the host terminal emulator;
  # TERM=linux skips Home Manager's starship init and triggers adjust_to_linux_vt.
  systemd.services."serial-getty@" = {
    after = [ "home-manager-user.service" ];
    wants = [ "home-manager-user.service" ];
    serviceConfig = {
      ExecStart = [
        ""
        "${pkgs.util-linux}/sbin/agetty --autologin user --noclear --keep-baud 115200,38400,9600 - xterm-256color"
      ];
    };
  };

  # Order sshd after UID sync and home-manager activation so SSH logins see final UID and shell setup
  systemd.services.sshd = {
    after = [
      "sync-user-uid.service"
      "home-manager-user.service"
    ];
    wants = [
      "sync-user-uid.service"
      "home-manager-user.service"
    ];
  };

  # Ensure user state directories exist and owned by user before home-manager activation script runs
  # The '+' prefix runs commands with full root privileges even when Service.User is 'user'.
  systemd.services."home-manager-user" = {
    after = [ "sync-user-uid.service" ];
    wants = [ "sync-user-uid.service" ];
    serviceConfig = {
      ExecStartPre = [
        "+${pkgs.coreutils}/bin/mkdir -p /home/user/.local/state/nix/profiles /home/user/.local/state/home-manager/gcroots /home/user/repos"
        "+${pkgs.coreutils}/bin/chown user:users /home/user /home/user/repos"
        "+${pkgs.coreutils}/bin/chown -R user:users /home/user/.local"
      ];
      StandardOutput = "journal+console";
      StandardError = "journal+console";
    };
  };

  # Mount optional per-instance workspace 9p share when launched with --mount
  systemd.services."mount-workspace" = {
    description = "Mount optional 9p workspace share at /home/user/workspace";
    wantedBy = [ "multi-user.target" ];
    before = [ "sync-user-uid.service" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "mount-workspace" ''
        set -eu
        for tag_file in /sys/bus/virtio/devices/*/mount_tag; do
          [ -r "$tag_file" ] || continue
          if [ "$(${pkgs.coreutils}/bin/tr -d '\0' < "$tag_file")" = "workspace" ]; then
            ${pkgs.coreutils}/bin/mkdir -p /home/user/workspace
            ${pkgs.util-linux}/bin/mount -t 9p -o trans=virtio,version=9p2000.L,msize=104857600 workspace /home/user/workspace
            exit 0
          fi
        done
      '';
      StandardOutput = "journal+console";
      StandardError = "journal+console";
    };
  };

  # Dynamically synchronize sandbox user UID to match mounted host directory ownership
  # This avoids hardcoding host-specific numeric UIDs while ensuring seamless write access.
  systemd.services."sync-user-uid" = {
    description = "Synchronize guest user UID with mounted host directory";
    wantedBy = [ "multi-user.target" ];
    before = [ "home-manager-user.service" ];
    after = [
      "local-fs.target"
      "mount-workspace.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "sync-user-uid" ''
        set -eu
        if ${pkgs.util-linux}/bin/mountpoint -q /home/user/workspace; then
          TARGET_DIR="/home/user/workspace"
        else
          TARGET_DIR="/home/user/repos/github.com/kachick"
        fi
        if [ -d "$TARGET_DIR" ]; then
          TARGET_UID=$(${pkgs.coreutils}/bin/stat -c '%u' "$TARGET_DIR")
          CURRENT_UID=$(${pkgs.coreutils}/bin/id -u user)
          if [ -n "$TARGET_UID" ] && [ "$TARGET_UID" -ne 0 ] && [ "$TARGET_UID" -ne "$CURRENT_UID" ]; then
            echo "Synchronizing sandbox user UID from $CURRENT_UID to $TARGET_UID to match host directory ownership"
            ${pkgs.gnused}/bin/sed -i "s/^user:x:[0-9]*:/user:x:$TARGET_UID:/" /etc/passwd
            ${pkgs.coreutils}/bin/chown -h "$TARGET_UID" /home/user /home/user/repos || true
            if [ -d /home/user/.local ]; then
              ${pkgs.coreutils}/bin/chown -R "$TARGET_UID" /home/user/.local
            fi
          fi
        fi
      '';
      StandardOutput = "journal+console";
      StandardError = "journal+console";
    };
  };

  # Route guest DNS through the default gateway when the host exposes a DNS proxy on port 5354.
  #
  # WHY DNAT port 53 to 5354 instead of querying port 53 or hardcoding IPs:
  # libslirp intercepts packets sent to the gateway on port 53 and forwards them to the
  # first nameserver in host /etc/resolv.conf, which breaks when an inactive VPN entry sits
  # at the top. Redirecting gateway port 53 to 5354 in guest OUTPUT bypasses that hijack
  # while probing the runtime default gateway avoids hardcoded subnets and keeps DHCP DNS
  # untouched on hosts without the proxy.
  systemd.services."sandbox-host-dns" =
    let
      proxyPort = 5354;
      probePort = pkgs.writeShellScript "probe-dns-proxy" ''
        exec 3<>"/dev/tcp/$1/${toString proxyPort}"
        exec 3>&-
      '';
    in
    {
      description = "Prefer host DNS proxy at default gateway when available";
      wantedBy = [ "multi-user.target" ];
      after = [
        "systemd-networkd.service"
        "systemd-resolved.service"
      ];
      wants = [
        "systemd-networkd.service"
        "systemd-resolved.service"
      ];
      path = [
        pkgs.iproute2
        pkgs.iptables
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -eu
        for _ in $(seq 1 50); do
          gw=""
          dev=""
          while read -r -a tokens; do
            [ "''${tokens[0]:-}" = "default" ] || continue
            gw=""
            dev=""
            for ((i = 1; i < ''${#tokens[@]}; i++)); do
              case "''${tokens[i]}" in
                via) gw="''${tokens[i + 1]:-}" ;;
                dev) dev="''${tokens[i + 1]:-}" ;;
              esac
            done
            if [ -n "$gw" ] && [ -n "$dev" ]; then
              break
            fi
          done < <(ip -4 route show default)

          if [ -n "$gw" ] && [ -n "$dev" ]; then
            if timeout 1 ${probePort} "$gw" 2>/dev/null; then
              for proto in udp tcp; do
                if ! iptables -t nat -C OUTPUT -d "$gw" -p "$proto" --dport 53 -j DNAT --to-destination "$gw:${toString proxyPort}" 2>/dev/null; then
                  iptables -t nat -A OUTPUT -d "$gw" -p "$proto" --dport 53 -j DNAT --to-destination "$gw:${toString proxyPort}"
                fi
              done
              resolvectl dns "$dev" "$gw"
            fi
            exit 0
          fi
          sleep 0.1
        done
      '';
    };

  # Normal user account in sandbox without hardcoded UID
  users.users.user = {
    isNormalUser = true;
    createHome = true;
    home = "/home/user";
    extraGroups = [ "wheel" ];
    password = "";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = import ../../../config/ssh/keys.nix;
  };

  security.sudo.enable = lib.mkForce false;
  security.sudo-rs = {
    enable = lib.mkForce true;
    wheelNeedsPassword = false;
  };
  security.pam.services.login.allowNullPassword = true;

  # Suppress zsh-newuser-install wizard and export ZDOTDIR for instant shell readiness
  programs.zsh = {
    enable = true;
    shellInit = ''
      zsh-newuser-install() { :; }
    '';
  };
  environment.etc."zshenv".text = ''
    export ZDOTDIR="''${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
  '';

  # Expose host-installed tools (such as antigravity-cli on unfree desktop hosts)
  # without baking unfree packages into the sandbox closure.
  # Append via extraInit rather than prepending via home.sessionPath so guest
  # /run/wrappers/bin (setuid sudo) and guest profiles keep precedence.
  environment.extraInit = lib.mkAfter ''
    export PATH="$PATH:/run/host-system-sw/bin"
  '';

  home-manager.users.user = {
    imports = [
      outputs.homeManagerModules.ephemeral
      outputs.homeManagerModules.dev
      outputs.homeManagerModules.containers
      ({ ... }: {
        # The host repos mount creates /home/user/repos before HM activation.
        # Disable repos/.keep to avoid permission errors when managing repos directory.
        home.file."repos/.keep".enable = false;

        # Disable 9p-slow compinit in sandbox for instant shell startup
        programs.zsh.enableCompletion = lib.mkForce false;
      })
    ];
  };
}
