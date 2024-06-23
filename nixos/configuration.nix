# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  inputs,
  config,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-desktop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # Select internationalisation properties.
  i18n.defaultLocale = "ja_JP.UTF-8";

  i18n.extraLocaleSettings = {
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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver = {
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Didn't work for current device
  # services.fprintd = {
  #   enable = true;

  #   # https://gitlab.freedesktop.org/libfprint/libfprint/-/issues/402#note_1860665

  #   # https://discourse.nixos.org/t/cannot-enroll-fingerprints-with-fprintd-no-devices-available/40362
  #   tod = {
  #     enable = true;
  #     driver = pkgs.libfprint-2-tod1-elan;
  #   };

  #   # https://github.com/NixOS/nixpkgs/issues/298150
  #   package = pkgs.fprintd.overrideAttrs {
  #     mesonCheckFlags = [
  #       "--no-suite"
  #       "fprintd:TestPamFprintd"
  #     ];
  #   };
  # };

  # https://sbulav.github.io/nix/nix-fingerprint-authentication/
  security.pam.services.swaylock = { };
  security.pam.services.swaylock.fprintAuth = true;

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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    kachick = {
      isNormalUser = true;
      description = "An admin";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
  };

  i18n.inputMethod = {
    enabled = "fcitx5";

    fcitx5.addons = [
      pkgs.fcitx5-mozc
      pkgs.fcitx5-gtk
    ];
  };

  services.dbus.packages = [ config.i18n.inputMethod.package ];

  # Allow unfree packages
  # Be careful to deploy containers if true, and it may take longtime in CI for non binary caches
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    micro
    alacritty
    # Using latest to avoid stable release and wayland problems https://github.com/wez/wezterm/issues/5340
    inputs.wezterm-flake.packages.${pkgs.system}.default

    wget
    curl
    git
    bat
    coreutils
    findutils
    fd
    fzf
    ripgrep
    typos-lsp

    # https://github.com/NixOS/nixpkgs/issues/33282
    xdg-user-dirs
    vscodium
    firefox

    ## Unfree packages
    vscode

    # if you changed hostname and chrome doesn't run, see https://askubuntu.com/questions/476918/google-chrome-wont-start-after-changing-hostname
    # `rm -rf ~/.config/google-chrome/Singleton*`
    google-chrome
  ];

  # https://github.com/NixOS/nixpkgs/issues/33282#issuecomment-523572259
  environment.etc."xdg/user-dirs.defaults".text = ''
    DESKTOP=Desktop
    DOCUMENTS=Documents
    DOWNLOAD=Downloads
    MUSIC=Music
    PICTURES=Pictures
    PUBLICSHARE=Public
    TEMPLATES=Templates
    VIDEOS=Videos
  '';

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

  programs.hyprland.enable = true;

  programs.nix-ld.enable = false;

  fonts.packages = with pkgs; [
    ibm-plex
    plemoljp-nf
    inputs.beedii-nixpkgs.legacyPackages.${pkgs.system}.beedii
    source-han-code-jp # Includes many definitions, useful for fallback
    inconsolata
    mplus-outline-fonts.githubRelease
    # sarasa-gothic # Large filesize
  ];
}
