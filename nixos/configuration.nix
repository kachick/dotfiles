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
    (import ./font.nix { inherit pkgs homemade-pkgs; })
    (import ./console.nix { inherit pkgs; })
    (import ./language.nix { inherit config pkgs; })
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
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

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # Allow unfree packages
  # Be careful to deploy containers if true, and it may take longtime in CI for non binary caches
  nixpkgs.config.allowUnfree = true;

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    SSH_ASKPASS_REQUIRE = "prefer";
    NIXOS_OZONE_WL = "1";
  };

  services.packagekit = {
    enable = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  services.blueman.enable = true;

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

  environment.variables = {
    # Required in both GNOME and KDE
    XMODIFIERS = "@im=fcitx";
    # https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland
    # Don't set these in KDE, but should set in GNOME https://discuss.kde.org/t/kde-plasma-wayland/9014
    QT_IM_MODULE = "fcitx";
    GTK_IM_MODULE = "fcitx";

    EDITOR = lib.getExe pkgs.micro;
    SYSTEMD_EDITOR = lib.getExe pkgs.micro;
    VISUAL = lib.getExe pkgs.micro;
  };

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

      wget
      curl
      git
      bat
      coreutils
      findutils
      fd
      fzf
      ripgrep

      # 3rd-party bitwarden helper, because of official cli does not have many core features
      # Use latest because of nixos-24.05 distributing version has a crucial bug: https://github.com/quexten/goldwarden/issues/190
      edge-pkgs.goldwarden

      # Clipboard
      #
      # Don't use clipcat, copyq for wayland problem
      # Dont' use cliphist for electron problem: https://www.reddit.com/r/NixOS/comments/1d57zbj/problem_with_cliphist_and_electron_apps/
      # Don't use clipse that depending wl-clipboard makes flickers in gnome
      #
      # So use a clipboard gnome extension

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
              --add-flags "--disable-features=WaylandFractionalScaleV1"
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
      kimpanel
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

  programs.nix-ld.enable = false;

  # Prefer NixOS modules rather than home-manager for easy setting up
  programs.goldwarden = {
    package = edge-pkgs.goldwarden;
    enable = true;
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
