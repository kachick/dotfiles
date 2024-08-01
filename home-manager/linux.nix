{
  pkgs,
  lib,
  homemade-pkgs,
  ...
}:

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

    # For implementation, handling bitwarden logins which contains space seprared text here looks complex and buggy. So extracted to a script.
    # And the dependent goldwarden does not support darwin yet: https://github.com/NixOS/nixpkgs/pull/278362/files#diff-062253d551cb2a1ebc07a298c69c8b69b1fb1152e8b08dc805e170ffe8134ae3R45
    home.sessionVariables.RCLONE_PASSWORD_COMMAND = lib.getExe homemade-pkgs.get-rclone-config-password;
  })
]
