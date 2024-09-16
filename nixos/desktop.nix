{
  pkgs,
  edge-pkgs,
  lib,
  ...
}:
{
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

  environment.systemPackages = with pkgs; [
    # gnome-music does not support flac.
    # tramhao/termusic and tsirysndr/music-player does not figure how to use.
    rhythmbox
  ];

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
}
