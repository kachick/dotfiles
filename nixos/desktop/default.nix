{
  config,
  inputs,
  pkgs,
  edge-pkgs,
  homemade-pkgs,
  lib,
  ...
}:

{
  imports = [
    (import ./font.nix { inherit pkgs homemade-pkgs; })
    inputs.xremap-flake.nixosModules.default
    ./xremap.nix
    inputs.home-manager.nixosModules.home-manager
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
      ];
      packages = [
        # Don't install spotify, it does not activate IME and no binary cache with the unfree license.
        # Use Web Player or PWA
      ];
    };
  };

  services.xserver = {
    enable = true;

    # Don't use other DM like SDDM, LightDM, lemurs for now. They don't start GNOME for now... (AFAIK)
    # And when I was using KDE, GDM only worked, SDDM didn't work
    # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/x11/display-managers/gdm.nix
    displayManager.gdm.enable = true;
    # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/x11/display-managers/lightdm.nix
    # displayManager.lightdm.enable = false;

    desktopManager.gnome = {
      enable = true;
      # https://github.com/NixOS/nixpkgs/issues/114514
      extraGSettingsOverridePackages = [ pkgs.gnome.mutter ];
    };

    # Configure keymap in X11
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

  # https://nixos.wiki/wiki/Virt-manager
  #
  # distrobox is a container based solution, not vm. And see https://github.com/89luca89/distrobox/issues/958
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  programs = {
    # https://github.com/nix-community/home-manager/blob/release-24.05/modules/misc/dconf.nix#L39-L42
    dconf.enable = true;
    # For lanching with command looks like better than alacritty
    gnome-terminal.enable = true;
  };

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
      gnome-music # does not support flac by defaults
    ]);

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput = {
    enable = true;
    mouse.naturalScrolling = true;
    touchpad.naturalScrolling = true;
  };

  services.dbus.packages = [ config.i18n.inputMethod.package ];

  services.blueman.enable = true;

  environment.systemPackages =
    [
      # version in nixos-24.05 does not enable IME
      # Don't use `buildFHSEnv` even through want to apply LSP smart. See GH-809
      edge-pkgs.zed-editor
      # Adding for zed instead of zeditor since https://github.com/NixOS/nixpkgs/pull/344193. Also keep original zed-editor package here to add icons for GUI
      homemade-pkgs.zed
    ]
    ++ (with pkgs; [
      firefox

      # https://github.com/NixOS/nixpkgs/issues/33282
      xdg-user-dirs

      alacritty
      foot
      kitty

      # TODO: Reconsider to drop this
      skk-dicts
      skktools

      lapce # IME is not working on Windows, but stable even around IME on Wayland than vscode

      # Add LSP global for zed-editor. Prefer external package for helix
      typos-lsp
      vscode-langservers-extracted
      nodePackages.bash-language-server

      # gnome-music does not support flac.
      # tramhao/termusic and tsirysndr/music-player does not figure how to use.
      rhythmbox

      evtest # To debug keyremapper as GH-786

      newsflash # RSS reader # TODO: Manage config (sqlite?) or Backup the exported OPML

      # Don't use unstable channel. It frequently backported to stable channel
      #   - https://github.com/NixOS/nixpkgs/commits/nixos-24.05/pkgs/applications/networking/instant-messengers/signal-desktop/signal-desktop.nix
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

      gnome.dconf-editor
      gnome.gnome-boxes

      # https://github.com/NixOS/nixpkgs/issues/174353 - Super + / runs launcher by default
      pop-launcher

      nordic

      ## Unfree packages

      # TODO: Consider using vscodium again
      # TODO: Consider to drop the unuseful vscode until fixed the Wayland problems
      # Don't use unstable channel. It frequently backported to stable channel
      #   - https://github.com/NixOS/nixpkgs/commits/nixos-24.05/pkgs/applications/editors/vscode/vscode.nix
      (vscode.override (prev: {
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

      # Don't use unstable channel. It frequently backported to stable channel
      #  - https://github.com/NixOS/nixpkgs/commits/nixos-24.05/pkgs/by-name/go/google-chrome/package.nix
      #  - Actually unstable is/was broken. See GH-776
      #
      # if you changed hostname and chrome doesn't run, see https://askubuntu.com/questions/476918/google-chrome-wont-start-after-changing-hostname
      # `rm -rf ~/.config/google-chrome/Singleton*`
      (google-chrome.override (prev: {
        # https://wiki.archlinux.org/title/Chromium#Native_Wayland_support
        # Similar as https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/chromium.nix
        commandLineArgs = (prev.commandLineArgs or [ ]) ++ [
          "--ozone-platform=wayland"
          "--ozone-platform-hint=auto"
          "--enable-wayland-ime"
        ];
      }))
    ])
    ++ (with pkgs.gnomeExtensions; [
      appindicator

      # Should be changed from default CSS to another to avoid https://github.com/pop-os/shell/issues/132
      # https://github.com/pop-os/shell/blob/cfa0c55e84b7ce339e5ce83832f76fee17e99d51/light.css#L20-L24
      # Apple same color as nord(Nordic) https://github.com/EliverLara/Nordic/blob/5c53654fb6f3e0266ad8c481a099091e92f28274/gnome-shell/_colors.scss#L14-L15
      (pop-shell.overrideAttrs (prev: {
        preFixup =
          prev.preFixup
          + ''
            echo '.pop-shell-search-element:select{ background: #8fbcbb !important; color: #fefefe !important; }' >> $out/share/gnome-shell/extensions/pop-shell@system76.com/light.css
          '';
      }))
      clipboard-history
      kimpanel
      just-perfection
      dash-to-dock
      color-picker
      xremap
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
      runtimeInputs = with edge-pkgs; [ cloudflare-warp ];
      text = ''
        warp-cli connect
      '';
    }
  );

  environment.variables = {
    VISUAL = "${lib.getExe edge-pkgs.zed-editor} --wait";

    # Don't set *IM_MODULE in KDE: https://discuss.kde.org/t/kde-plasma-wayland/9014
    # QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";

    # Avoiding hidden or unstable mouse cursors when using Alacritty/Wezterm on Wayland
    #
    # https://github.com/NixOS/nixpkgs/issues/22652
    # https://github.com/alacritty/alacritty/issues/6703#issuecomment-2222503206
    XCURSOR_THEME = "Adwaita";
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

  # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/programs/firefox.nix
  programs.firefox = {
    enable = true;
    languagePacks = [
      "en-US"
      "ja"
    ];
  };

  i18n = {
    inputMethod = {
      enabled = "fcitx5";

      fcitx5.addons = [
        pkgs.fcitx5-mozc
        pkgs.fcitx5-gtk
      ];

      fcitx5.waylandFrontend = true;
    };
  };
}
