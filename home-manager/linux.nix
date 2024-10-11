{ pkgs, lib, ... }:

# https://github.com/nix-community/home-manager/issues/414#issuecomment-427163925
lib.mkMerge [
  (lib.mkIf pkgs.stdenv.isLinux {
    # This also changes xdg? Official manual sed this config is better for non NixOS Linux
    # https://github.com/nix-community/home-manager/blob/559856748982588a9eda6bfb668450ebcf006ccd/modules/targets/generic-linux.nix#L16
    targets.genericLinux.enable = true;

    # xdg-user-dirs NixOS module does not work or is not enough for me to keep English dirs even in Japanese locale.
    # Check your `~/.config/user-dirs.dirs` if you faced any trouble
    # https://github.com/nix-community/home-manager/blob/release-24.05/modules/misc/xdg-user-dirs.nix
    xdg = {
      userDirs = {
        enable = true;
        createDirectories = true;
      };

      configFile = {
        "hypr/hyprland.conf".source = ../config/hyprland/hyprland.conf;

        # https://github.com/NixOS/nixpkgs/issues/222925#issuecomment-1514112861
        "autostart/userdirs.desktop".text = ''
          [Desktop Entry]
          Exec=xdg-user-dirs-update
          TryExec=xdg-user-dirs-update
          NoDisplay=true
          StartupNotify=false
          Type=Application
          X-KDE-AutostartScript=true
          X-KDE-autostart-phase=1
        '';

        # Should sync with the directory instead of each file. See https://github.com/nix-community/home-manager/issues/3090#issuecomment-1799268943
        fcitx5 = {
          source = ../config/fcitx5;
        };
      };
    };
  })
]
