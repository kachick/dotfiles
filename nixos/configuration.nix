# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  edge-pkgs,
  homemade-pkgs,
  lib,
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

  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/misc/dconf.nix#L39-L42
  programs.dconf.enable = true;

  environment.gnome.excludePackages =
    (with pkgs; [
      gnome-tour
      gnome-connections
    ])
    ++ (with pkgs.gnome; [
      epiphany # web browser
      geary # email reader
      evince # document viewer
      gnome-calendar
    ]);

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    SSH_ASKPASS_REQUIRE = "prefer";
    NIXOS_OZONE_WL = "1";
  };

  programs.hyprland.enable = false;

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

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  services.blueman.enable = true;

  services.fprintd = {
    enable = true;

    # https://gitlab.freedesktop.org/libfprint/libfprint/-/issues/402#note_1860665

    # https://discourse.nixos.org/t/cannot-enroll-fingerprints-with-fprintd-no-devices-available/40362
    tod = {
      enable = true;
      # This select is a bit different of https://github.com/ramaureirac/thinkpad-e14-linux/blob/7539f51b1c29d116a549265f992032aa9642d4a5/tweaks/fingerprint/README.md#L19
      # You should check actual vendor with `lsusb | grep FingerPrint`
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/pkgs/development/libraries/libfprint-2-tod1-goodix-550a/default.nix#L9
      driver = pkgs.libfprint-2-tod1-goodix-550a;
    };

    # https://github.com/NixOS/nixpkgs/issues/298150
    # package = pkgs.fprintd.overrideAttrs {
    #   mesonCheckFlags = [
    #     "--no-suite"
    #     "fprintd:TestPamFprintd"
    #   ];
    # };
  };

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
    touchpad.naturalScrolling = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    kachick = {
      isNormalUser = true;
      description = "An admin";
      extraGroups = [
        "networkmanager"
        "wheel"
        "input" # For finger print in GDM
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
  environment.systemPackages =
    with pkgs;
    [
      vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      micro
      edge-pkgs.zed-editor # version in nixos-24.05 does not enable IME
      lapce # IME is not working on Windows, but stable even around IME on Wayland than vscode

      usbutils # `lsusb` to get IDs

      skk-dicts
      skktools

      alacritty
      # Don't use nightly wezterm, that still does not enable IME on wayland
      # inputs.wezterm-flake.packages.${pkgs.system}.default
      wezterm

      waybar

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

      (signal-desktop.overrideAttrs (prev: {
        preFixup =
          prev.preFixup
          + ''
            gappsWrapperArgs+=(
              --add-flags "--enable-features=UseOzonePlatform"
              --add-flags "--ozone-platform=wayland"
              --add-flags "--enable-wayland-ime"
            )
          '';
      }))

      podman-tui
      docker-compose

      ## Unfree packages

      (edge-pkgs.vscode.override (prev: {
        # https://wiki.archlinux.org/title/Wayland#Electron
        # https://github.com/NixOS/nixpkgs/blob/3f8b7310913d9e4805b7e20b2beabb27e333b31f/pkgs/applications/editors/vscode/generic.nix#L207-L214
        commandLineArgs = (prev.commandLineArgs or [ ]) ++ [
          "--enable-features=UseOzonePlatform"
          "--ozone-platform=wayland"
          "--enable-wayland-ime"
          # https://github.com/microsoft/vscode/issues/192590#issuecomment-1731312805
          # This bug appeared only when using GNOME, not in KDE
          "--disable-features=WaylandFractionalScaleV1"
        ];
      }))

      # if you changed hostname and chrome doesn't run, see https://askubuntu.com/questions/476918/google-chrome-wont-start-after-changing-hostname
      # `rm -rf ~/.config/google-chrome/Singleton*`
      (edge-pkgs.google-chrome.override (prev: {
        # https://wiki.archlinux.org/title/Chromium#Native_Wayland_support
        # Similar as https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/chromium.nix
        commandLineArgs = (prev.commandLineArgs or [ ]) ++ [
          "--ozone-platform=wayland"
          "--ozone-platform-hint=auto"
          "--enable-wayland-ime"
        ];
      }))

      cloudflare-warp
    ]
    ++ (with pkgs.gnomeExtensions; [
      appindicator
      blur-my-shell
      pop-shell
      clipboard-history
    ]);

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

  # Make it natural scroll on KDE, not enough only in libinput
  # https://github.com/NixOS/nixpkgs/issues/51875#issuecomment-846251880
  # environment.etc."X11/xorg.conf.d/30-touchpad.conf".text = ''
  #   Section "InputClass"
  #           Identifier "libinput touchpad catchall"
  #           MatchIsTouchpad "on"
  #           MatchDevicePath "/dev/input/event*"
  #           Driver "libinput"
  #           Option "NaturalScrolling" "on"
  #   EndSection
  # '';

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
      # sarasa-gothic # Drop this because of the large filesize

      # emoji
      noto-fonts-color-emoji
      homemade-pkgs.beedii
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

  # Apply better fonts for non X consoles
  # https://github.com/NixOS/nixpkgs/issues/219239
  boot.initrd.kernelModules = [ "amdgpu" ];
  # https://wiki.archlinux.org/title/Linux_console
  console = {
    earlySetup = true;
    # The font should have PSF formats. Do not specify TTF and OTF
    # You can list current glyphs with `showconsolefont`
    font = "ter-u24n";

    packages = with pkgs; [
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/pkgs/data/fonts/terminus-font/default.nix#L41-L43
      terminus_font
    ];
    keyMap = "us";
  };

  # Better console appearance even if no X, but do not use for now with the unstable behaviors
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/ttys/kmscon.nix
  services.kmscon = {
    enable = false;
    hwRender = false;
    fonts = with pkgs; [
      {
        name = "IBM Plex Mono";
        package = ibm-plex;
      }
      {
        name = "Noto Color Emoji";
        package = noto-fonts-color-emoji;
      }
    ];
    extraConfig = "font-size=24";
    extraOptions = "--term xterm-256color";
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

  # https://github.com/NixOS/nixpkgs/issues/213177#issuecomment-1905556283
  systemd.packages = [ pkgs.cloudflare-warp ]; # for warp-cli
  systemd.targets.multi-user.wants = [ "warp-svc.service" ]; # causes warp-svc to be started automatically
}
