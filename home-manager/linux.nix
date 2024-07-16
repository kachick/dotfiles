{ pkgs, lib, ... }:

# https://github.com/nix-community/home-manager/issues/414#issuecomment-427163925
lib.mkMerge [
  (lib.mkIf pkgs.stdenv.isLinux {
    # xdg-user-dirs NixOS module does not work or is not enough for me to keep English dirs even in Japanese locale.
    # Check your `~/.config/user-dirs.dirs` if you faced any trouble
    # https://github.com/nix-community/home-manager/blob/release-24.05/modules/misc/xdg-user-dirs.nix
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };

    xdg.configFile."hypr/hyprland.conf".source = ../config/hyprland/hyprland.conf;
  })

  (lib.mkIf pkgs.stdenv.isLinux (import ./gnome.nix { }))
]
