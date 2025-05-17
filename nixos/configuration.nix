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

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Bootloader.
  boot.loader.efi.canTouchEfiVariables = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

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

  # TODO: Reconsider to drop this
  services.packagekit = {
    enable = true;
  };

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
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

  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/networking/cloudflare-warp.nix
  services.cloudflare-warp = {
    enable = true;
    package = pkgs.unstable.cloudflare-warp;
  };

  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/config/shells-environment.nix
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

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # programs.nix-ld.enable = false;

  # Don't use podman NixOS module. It works under rootful mode and conflict with rootless podman in several socket based tools (e.g. podman-tui, act).
  # https://github.com/NixOS/nixpkgs/blob/24.05/nixos/modules/virtualisation/containers.nix
  virtualisation.containers = {
    enable = true;
    policy = builtins.fromJSON (builtins.readFile ../config/containers/policy.json);
  };
}
