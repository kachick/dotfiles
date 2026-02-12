# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  pkgs,
  overlays,
  ...
}:
{
  imports = [
    (import ./console.nix { inherit pkgs; })
    (import ./locale.nix { })
  ];

  # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/config/nix.nix
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # `trusted-users = root` by default on NixOS 25.11
    # Setting another helps us to use binary cache substituters in flake.nix
    # Only using `--accept-flake-config` is not enough
    trusted-users = [
      "root"
      "@wheel"
    ];

    # Enabled by default on https://github.com/DeterminateSystems/nix-installer/releases/tag/v3.8.5
    # Therefore enable also on NixOS to keep consistency against other Linux distros and macOS
    # See https://github.com/NixOS/nix/pull/8047 for background
    always-allow-substitutes = true;

    trusted-substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
      "kachick-dotfiles.cachix.org-1:XhiP3JOkqNFGludaN+/send30shcrn1UMDeRL9XttkI="
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" # https://nix-community.org/cache/
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "kachick-dotfiles.cachix.org-1:XhiP3JOkqNFGludaN+/send30shcrn1UMDeRL9XttkI=" # GH-1235
    ];

    accept-flake-config = true;

    # Workaround for https://github.com/NixOS/nix/issues/11728
    download-buffer-size =
      let
        GiB = 1024 * 1024 * 1024;
      in
      1 * GiB;
  };

  # Enabling might cause heavy build time: https://github.com/NixOS/nix/issues/6033#issuecomment-1028697508
  # nix.settings.auto-optimise-store = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nix.extraOptions = ''
    min-free = ${toString (100 * 1024 * 1024)}
    max-free = ${toString (1024 * 1024 * 1024)}
  '';

  # Bootloader.
  boot.loader.efi.canTouchEfiVariables = true;

  # GH-1255 for HDD
  # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/hardware/iosched.nix
  hardware.block.defaultSchedulerRotational = "bfq";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # TODO: Reconsider to set UTC for servers
  time.timeZone = "Asia/Tokyo";

  nixpkgs = {
    inherit overlays;

    # Allow unfree packages
    # Be careful to deploy containers if true, and it may take longtime in CI for non binary caches
    config.allowUnfree = true;
  };

  systemd = {
    # https://github.com/NixOS/nixpkgs/blob/8e5e5a6add04c7f1e38e76f59ada6732947f1e55/nixos/doc/manual/release-notes/rl-2411.section.md?plain=1#L69-L76
    enableStrictShellChecks = true;
  };

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  # Avoid conflicting since using pipewire for enabling sound.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/services/networking/cloudflare-warp.nix
  services.cloudflare-warp = {
    enable = true;
    package = pkgs.unstable.cloudflare-warp;
  };

  # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/config/shells-environment.nix
  # The final definition will be put on /etc/set-environment
  # And you can custom it with /etc/profile.local and/or /etc/bashrc.local
  environment.variables = {
    DO_NOT_TRACK = "1";
    EDITOR = pkgs.helix.meta.mainProgram;
    SYSTEMD_EDITOR = pkgs.helix.meta.mainProgram;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = (
    with pkgs;
    [
      vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      helix
      micro

      usbutils # `lsusb` to get IDs

      wget
      curl
      git
      bat
      coreutils
      findutils
      fd
      fzf
      ripgrep
      dig

      dmidecode # `sudo dmidecode -s bios-version`
    ]
  );

  ## Avahi (Classic, supported by CUPS)
  # - https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/services/networking/avahi-daemon.nix
  # - https://wiki.archlinux.org/title/Avahi
  #
  # If you faced to any troubles around this context, Also see following issues
  # - https://github.com/NixOS/nixpkgs/issues/118628
  # - https://github.com/NixOS/nixpkgs/issues/412777
  # - https://github.com/NixOS/nixpkgs/issues/291108
  # I don't know how to use both in NixOS likely https://wiki.archlinux.org/index.php?title=CUPS&diff=prev&oldid=806890
  services.avahi = {
    # Enable auto detect for wireless printers. CUPS does not support systemd-resolved
    # - https://github.com/apple/cups/issues/5452
    # - https://github.com/OpenPrinting/libcups/issues/81
    enable = true; # If enabled, you should care the conflict with systemd-resolved

    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };

    # I don't know how to realize enabling DNS-SD but disable mDNS: https://wiki.archlinux.org/index.php?title=CUPS&diff=prev&oldid=806890
    # Check the log with `journalctl -u systemd-resolved -u avahi-daemon -r`
    # I prefer systemd-resolved for mDNS use, because of enabling on Avahi makes much flaky resolutions
    # You can test it with: `avahi-resolve-host-name hostname.local` if enabled

    nssmdns4 = false;
    nssmdns6 = false;
  };

  ## systemd-resolved (Modern, not supported by CUPS)
  # - Check the behavior with `resolvectl status`
  # - https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/system/boot/resolved.nix
  # - https://wiki.archlinux.org/title/Systemd-resolved
  # Disabled by default. But ensures to disable MulticastDNS
  services.resolved = {
    enable = true;
    llmnr = "false";

    # Enable mDNS(hostname.local). Use resolve mode to avoid conflict with Avahi responder.
    # - https://github.com/systemd/systemd/pull/40133
    # - https://www.freedesktop.org/software/systemd/man/latest/resolved.conf.html
    extraConfig = ''
      MulticastDNS=resolve
      DNSStubListener=false
    '';
  };

  # Avahi module has openFirewall, but resolved module does not have it
  networking.firewall.allowedUDPPorts = [ 5353 ];

  # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/services/networking/networkmanager.nix
  networking.networkmanager = {
    enable = true;

    dns = "systemd-resolved";
    # 1 means 'resolve' (resolve only, no announcement)
    # See https://networkmanager.dev/docs/api/latest/nm-settings-nmcli.html
    connectionConfig."connection.mdns" = 1;

    # TIPS: If you are debugging, dmesg with ctime/iso will display incorrect timestamp
    # Then `journalctl --dmesg --output=short-iso --since='1 hour ago' --follow` might be useful
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;

  # List services that you want to enable:

  # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/services/networking/ssh/sshd.nix
  # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/doc/manual/configuration/ssh.section.md
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.fail2ban.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # programs.nix-ld.enable = false;

  # Didn't use podman NixOS module on nixos-24.05. It worked under rootful mode and conflict with rootless podman in several socket based tools (e.g. podman-tui, act).
  # I may reconsider to use the latest NixOS module now, however current home-manager based setup seems working for me. It is also useful on WSL2 and Lima
  # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/virtualisation/containers.nix
  virtualisation.containers = {
    enable = true;
    policy = builtins.fromJSON (builtins.readFile ../config/containers/policy.json);
  };

  # To test https://github.com/NixOS/nixpkgs/pull/459211
  virtualisation.containerd = {
    enable = true;
  };

  # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/security/sudo-rs.nix
  security.sudo-rs.enable = true;
}
