# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  beedii = pkgs.callPackage ../pkgs/beedii.nix { };
in
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

  # Allow unfree packages
  # Be careful to deploy containers if true, and it may take longtime in CI for non binary caches
  nixpkgs.config.allowUnfree = true;

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
  # services.xserver.displayManager.sddm.wayland.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;
  services = {
    desktopManager.plasma6.enable = true;
    # displayManager = {
    #   sddm.enable = true;
    #   defaultSession = "plasma";
    # };
  };
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    oxygen
  ];
  # qt = {
  #   enable = true;
  #   platformTheme = "gnome";
  #   style = "adwaita-dark";
  # };
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    SSH_ASKPASS_REQUIRE = "prefer";
  };

  services.packagekit = {
    enable = true;
  };

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
  services.libinput = {
    enable = true;
    mouse.naturalScrolling = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    kachick = {
      isNormalUser = true;
      description = "An admin";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      packages = [
        # Don't install spotify, it does not activate IME and no binary cache with the unfree license.
        # Use the Web Player via Firefox
      ];
    };
  };

  i18n.inputMethod = {
    enabled = "fcitx5";

    fcitx5.addons = [
      pkgs.fcitx5-mozc
      pkgs.fcitx5-gtk
    ];

    fcitx5.waylandFrontend = true;
  };

  environment.variables = {
    # Don't set *IM_MODULE in KDE: https://discuss.kde.org/t/kde-plasma-wayland/9014
    # QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";

    EDITOR = lib.getExe pkgs.micro;
    SYSTEMD_EDITOR = lib.getExe pkgs.micro;
    VISUAL = lib.getExe pkgs.micro;
  };

  services.dbus.packages = [ config.i18n.inputMethod.package ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    micro

    skk-dicts
    skktools

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

    # Don't use clipcat, copyq for wayland problem
    # Dont' use cliphist for electron problem: https://www.reddit.com/r/NixOS/comments/1d57zbj/problem_with_cliphist_and_electron_apps/
    clipse
    # Required in clipse
    wl-clipboard

    # https://github.com/NixOS/nixpkgs/issues/33282
    xdg-user-dirs

    # Use stable packages even for GUI apps, because of using home-manager stable channel

    firefox

    signal-desktop

    ## Unfree packages
    vscode

    # if you changed hostname and chrome doesn't run, see https://askubuntu.com/questions/476918/google-chrome-wont-start-after-changing-hostname
    # `rm -rf ~/.config/google-chrome/Singleton*`
    google-chrome

    cloudflare-warp
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

  programs.nix-ld.enable = false;

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      ibm-plex
      plemoljp-nf
      inconsolata
      mplus-outline-fonts.githubRelease
      # sarasa-gothic # Avoiding because of the large filesize

      # emoji
      noto-fonts-color-emoji
      beedii
      twemoji-color-font

      # Source Han family includes many definitions, useful for fallback
      source-han-code-jp
      source-han-sans-japanese
      source-han-serif-japanese
    ];
    fontconfig = {
      enable = true;
      hinting.enable = true;
      defaultFonts = {
        serif = [
          "IBM Plex Serif"
          "Source Han Serif"
        ];
        sansSerif = [
          "IBM Plex Sans"
          "Source Han Sans"
        ];
        monospace = [
          "PlemolJP Console NF"
          "Source Han Code JP"
        ];
        emoji = [
          "Beedii"
          "Noto Color Emoji"
        ];
      };
    };
  };

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

  # https://nixos.wiki/wiki/OneDrive
  services.onedrive.enable = true;
}
