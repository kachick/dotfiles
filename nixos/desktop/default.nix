{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    (import ./font.nix { inherit pkgs; })
    ./kanata.nix
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    kachick = {
      isNormalUser = true;
      description = "An admin";
      extraGroups = [
        "networkmanager"
        "wheel"
        "input" # For finger print in GDM
        "libvirtd" # For virt-manager
        "scanner"
        "lp" # For scanner
      ];
      packages = [
        # Don't install spotify, it does not activate IME and no binary cache with the unfree license.
        # Use Web Player or PWA
      ];
    };
  };

  i18n = {
    # GNOME respects this, I don't know how to realize it only via home-manager
    defaultLocale = "ja_JP.UTF-8";
  };

  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/x11/xserver.nix
  services.xserver = {
    enable = true;

    # Don't use other DM like SDDM, LightDM, lemurs for now. They don't start GNOME for now... (AFAIK)
    # And when I was using KDE, GDM only worked, SDDM didn't work
    # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/x11/display-managers/gdm.nix
    displayManager.gdm.enable = true;
    # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/x11/display-managers/lightdm.nix
    # displayManager.lightdm.enable = false;

    desktopManager.gnome = {
      enable = true;
      # https://github.com/NixOS/nixpkgs/issues/114514
      extraGSettingsOverridePackages = [ pkgs.mutter ];
    };

    # Configure keymap in X11
    xkb = {
      layout = "us,jp"; # multiple specifier is available
      variant = "";
    };

    # Make it possible to use `localectl list-keymaps`. See https://github.com/NixOS/nixpkgs/issues/19629
    exportConfiguration = true;
  };

  services.udev.packages = with pkgs; [
    gnome-settings-daemon
    sane-airscan
  ];

  # To avoid unexpected overriding with the NixOS module. I prefer gpg-agent or another way for that.
  programs.ssh.enableAskPassword = false;

  # https://nixos.wiki/wiki/Virt-manager
  #
  # distrobox is a container based solution, not vm. And see https://github.com/89luca89/distrobox/issues/958
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  programs = {
    # https://github.com/nix-community/home-manager/blob/release-24.11/modules/misc/dconf.nix#L39-L42
    dconf.enable = true;
    # For lanching with command looks like better than alacritty
    gnome-terminal.enable = true;
  };

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-connections
    epiphany # web browser
    geary # email reader
    evince # document viewer
    gnome-calendar
    gnome-music # does not support flac by defaults
    gnome-online-accounts # See GH-1015
  ];

  # Recommended to be uninstalled by gnupg. I prefer this way, even though disabling gpg-agent ssh integrations.
  # https://wiki.gnupg.org/GnomeKeyring
  #
  # And enabling this makes $SSH_AUTH_SOCK overriding even through enabled gpg-agent in home-manager
  # https://github.com/NixOS/nixpkgs/issues/101616
  #
  # Using mkforce for https://discourse.nixos.org/t/gpg-smartcard-for-ssh/33689/3
  services.gnome.gnome-keyring.enable = lib.mkForce false;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput = {
    enable = true;
    mouse.naturalScrolling = true;
    touchpad.naturalScrolling = true;
  };

  services.dbus.packages = [ config.i18n.inputMethod.package ];

  services.blueman.enable = true;

  services.printing = {
    enable = true;
    drivers = [ pkgs.epson-escpr2 ];
  };

  # To setup a wireless printer
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  environment.systemPackages =
    (with pkgs; [
      firefox

      # https://github.com/NixOS/nixpkgs/issues/33282
      xdg-user-dirs

      cyme
      lshw

      # Don't use `buildFHSEnv` even through want to apply LSP smart. See GH-809
      zed-editor

      gdm-settings

      unstable.ghostty

      alacritty

      lapce # IME is not working on Windows, but stable even around IME on Wayland than vscode

      mission-center

      # Add LSP global for zed-editor. Prefer external package for helix
      typos-lsp
      nil
      nixd
      vscode-langservers-extracted
      bash-language-server

      # gnome-music does not support flac.
      # tramhao/termusic and tsirysndr/music-player does not figure how to use.
      rhythmbox

      evtest # To debug keyremapper as GH-786
      psmisc # e.g. `fuser -v /dev/input/event17` when want to know event17 is grabbed by which process

      newsflash # `io.gitlab.news_flash.NewsFlash`

      calibre

      dconf-editor
      gnome-boxes

      # https://github.com/NixOS/nixpkgs/issues/174353 - Super + / runs launcher by default
      pop-launcher

      nordic

      podman-desktop

      ## Unfree packages

      # TODO: Consider using vscodium again
      # Don't use unstable channel. It frequently backported to stable channel
      #   - https://github.com/NixOS/nixpkgs/commits/nixos-24.11/pkgs/applications/editors/vscode/vscode.nix
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/applications/editors/vscode/generic.nix#L207-L217
      (
        (vscode.override {
          # https://wiki.archlinux.org/title/Wayland#Electron
          # https://github.com/NixOS/nixpkgs/blob/3f8b7310913d9e4805b7e20b2beabb27e333b31f/pkgs/applications/editors/vscode/generic.nix#L207-L214
          commandLineArgs = [
            "--enable-wayland-ime=true" # TODO: Remove after https://github.com/NixOS/nixpkgs/pull/361341 introduced. At least nixos-25.05
            # TODO: Add `"--wayland-text-input-version=3"` after vscode updates the Electron to 33.0.0 or higher. See GH-689 for detail.

            # https://github.com/microsoft/vscode/blob/5655a12f6af53c80ac9a3ad085677d6724761cab/src/vs/platform/encryption/common/encryptionService.ts#L28-L71
            # https://github.com/microsoft/vscode/blob/5655a12f6af53c80ac9a3ad085677d6724761cab/src/main.ts#L244-L253
            "--password-store=gnome-libsecret" # Required for GitHub Authentication. For example gnome-keyring, kwallet5, KeepassXC, pass-secret-service
          ];
        }).overrideAttrs
        (prevAttrs: {
          # https://incipe.dev/blog/post/using-visual-studio-code-insiders-under-home-manager/#an-os-keyring-couldnt-be-identified-for-storing-the-encryption-related-data-in-your-current-desktop-environment
          runtimeDependencies = prevAttrs.runtimeDependencies ++ [ pkgs.libsecret ];
        })
      )

      # NOTE: Google might extract chrome from themself with `Antitrust` penalties
      #       https://edition.cnn.com/2024/11/20/business/google-sell-chrome-justice-department/
      #
      # Don't use chromium, it does not provide built-in cloud translations
      #
      # Don't use unstable channel. It frequently backported to stable channel
      #  - https://github.com/NixOS/nixpkgs/commits/nixos-24.11/pkgs/by-name/go/google-chrome/package.nix
      #  - Actually unstable is/was broken. See GH-776
      #
      # if you changed hostname and chrome doesn't run, see https://askubuntu.com/questions/476918/google-chrome-wont-start-after-changing-hostname
      # `rm -rf ~/.config/google-chrome/Singleton*`
      #
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/by-name/go/google-chrome/package.nix#L244-L253
      (google-chrome.override {
        # https://wiki.archlinux.org/title/Chromium#Native_Wayland_support
        # Similar as https://github.com/nix-community/home-manager/blob/release-24.11/modules/programs/chromium.nix
        commandLineArgs = [
          "--enable-wayland-ime=true" # TODO: Remove after https://github.com/NixOS/nixpkgs/pull/361341 introduced. At least nixos-25.05
          "--wayland-text-input-version=3"
        ];
      })
    ])
    ++ (with pkgs.gnomeExtensions; [
      appindicator
      paperwm
      clipboard-history
      kimpanel
      just-perfection
      dash-to-dock
      color-picker
    ]);

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

  # https://askubuntu.com/a/88947
  environment.etc."gdm/PostLogin/Default".source = lib.getExe (
    pkgs.writeShellApplication {
      name = "connect_cloudflare-warp";
      runtimeInputs = with pkgs; [ unstable.cloudflare-warp ];
      text = ''
        warp-cli connect
      '';
    }
  );

  environment.variables = {
    VISUAL = "${lib.getExe pkgs.zed-editor} --wait";

    XMODIFIERS = "@im=fcitx"; # Required in both GNOME and KDE

    # https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland
    # Don't set these in KDE, but should set in GNOME https://discuss.kde.org/t/kde-plasma-wayland/9014
    QT_IM_MODULE = "fcitx";
    GTK_IM_MODULE = "fcitx";
  };

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";

    # Avoiding hidden or unstable mouse cursors when using Alacritty/Wezterm on Wayland
    #
    # https://github.com/NixOS/nixpkgs/issues/22652
    # https://github.com/alacritty/alacritty/issues/6703#issuecomment-2222503206
    XCURSOR_THEME = "Adwaita";

    __HM_SESS_VARS_SOURCED = ""; # Workaround for GH-755 and GH-890
  };

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

  # Require add-on for built-in Japanese translations and multiple containers. It is a disadvantage than Chrome
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/programs/firefox.nix
  programs.firefox = {
    enable = true;
    languagePacks = [
      "en-US"
      "ja"
    ];
  };

  i18n = {
    inputMethod = {
      enable = true;
      type = "fcitx5";

      fcitx5.addons = [
        pkgs.fcitx5-mozc
        pkgs.fcitx5-gtk
      ];

      fcitx5.waylandFrontend = true;
    };
  };

  # TODO: Consider to use headscale
  services.tailscale.enable = true;
}
