{ pkgs, ... }:
{
  nixpkgs.allowedUnfreePackageNames = [
    "ludii-bin"
    "steam"
    "steam-unwrapped"
  ];

  environment.systemPackages = with pkgs; [
    local.ludii-bin

    (makeDesktopItem {
      name = "steam-gamescope";
      desktopName = "Steam (Gamescope)";
      comment = "Launch Steam inside Gamescope";
      icon = "steam";
      exec = "gamescope -- steam %U";
      categories = [
        "Network"
        "FileTransfer"
        "Game"
      ];
      # Match gamescope's Wayland app_id so GNOME Dash shows the Steam icon.
      startupWMClass = "gamescope";
      extraConfig = {
        PrefersNonDefaultGPU = "true";
      };
    })
  ];

  programs.steam = {
    enable = true;
    # Make gamescope available inside Steam's FHS environment as well as on the host.
    extraPackages = [ pkgs.gamescope ];
    # Isolate Steam and game binaries from real $HOME (~/.ssh, ~/repos, ~/.config) and /mnt
    # using Steam's existing buildFHSEnv bubblewrap layer instead of adding Flatpak.
    package = pkgs.steam.override {
      extraPreBwrapCmds = ''
        steam_home="''${XDG_DATA_HOME:-$HOME/.local/share}/steam-home"
        mkdir -p "$steam_home"
        ignored+=(/home /mnt)
      '';
      extraBwrapArgs = [
        ''--bind "$steam_home" "$HOME"''
        ''--chdir "$HOME"''
      ];
    };
  };
}
