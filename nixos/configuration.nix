# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  pkgs,
  edge-pkgs,
  homemade-pkgs,
  lib,
  ...
}:
{
  imports = [
    ./modules/cloudflare-warp.nix
    (import ./console.nix { inherit homemade-pkgs; })
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
  system.stateVersion = "24.05"; # Did you read the comment?

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/networking/networkmanager.nix
  networking.networkmanager = {
    enable = true;

    # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/networking/networkmanager.nix#L261-L289
    wifi = {
      # https://github.com/kachick/dotfiles/issues/663#issuecomment-2262189168
      powersave = false;
    };
  };

  # TODO: Reconsider to set UTC for servers
  time.timeZone = "Asia/Tokyo";

  # Allow unfree packages
  # Be careful to deploy containers if true, and it may take longtime in CI for non binary caches
  nixpkgs.config.allowUnfree = true;

  environment.sessionVariables = {
    SSH_ASKPASS_REQUIRE = "prefer";
  };

  # TODO: Reconsider to drop this
  services.packagekit = {
    enable = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  # Enable sound with pipewire.
  sound.enable = true;
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

  services.cloudflare-warp = {
    enable = true;
    # Use newer version to break down issues such as GH-749
    package = edge-pkgs.cloudflare-warp;
  };

  environment.variables = {
    EDITOR = lib.getExe pkgs.helix;
    SYSTEMD_EDITOR = lib.getExe pkgs.helix;
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

      # Clipboard
      #
      # Don't use clipcat, copyq for wayland problem
      # Dont' use cliphist for electron problem: https://www.reddit.com/r/NixOS/comments/1d57zbj/problem_with_cliphist_and_electron_apps/
      # Don't use clipse that depending wl-clipboard makes flickers in gnome
      #
      # So use a clipboard gnome extension

      # Use stable packages even for GUI apps, because of using home-manager stable channel

      podman-tui
      docker-compose

      chawan
    ]
  );

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # programs.nix-ld.enable = false;

  # https://nixos.wiki/wiki/Podman
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # TODO: Reconsider to set C or EN for servers
  # Select internationalisation properties.
  i18n = {
    defaultLocale = "ja_JP.UTF-8";

    extraLocaleSettings = {
      LC_ADDRESS = "ja_JP.UTF-8";
      LC_IDENTIFICATION = "ja_JP.UTF-8";
      LC_MEASUREMENT = "ja_JP.UTF-8";
      LC_MONETARY = "ja_JP.UTF-8";
      LC_NAME = "ja_JP.UTF-8";
      LC_NUMERIC = "ja_JP.UTF-8";
      LC_PAPER = "ja_JP.UTF-8";
      LC_TELEPHONE = "ja_JP.UTF-8";
      LC_TIME = "ja_JP.UTF-8";
    };
  };
}
