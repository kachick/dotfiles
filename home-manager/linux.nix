{
  pkgs,
  lib,
  edge-pkgs,
  homemade-pkgs,
  ...
}:

# https://github.com/nix-community/home-manager/issues/414#issuecomment-427163925
lib.mkMerge [
  (lib.mkIf pkgs.stdenv.isLinux {
    # This also changes xdg? Official manual sed this config is better for non NixOS Linux
    # https://github.com/nix-community/home-manager/blob/559856748982588a9eda6bfb668450ebcf006ccd/modules/targets/generic-linux.nix#L16
    targets.genericLinux.enable = true;

    home.packages = with pkgs; [
      # Fix missing locales as `locale: Cannot set LC_CTYPE to default locale`
      glibc

      # https://github.com/nix-community/home-manager/blob/a8f8f48320c64bd4e3a266a850bbfde2c6fe3a04/modules/services/ssh-agent.nix#L37
      openssh

      iputils # `ping` etc

      # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/iw/iw/package.nix
      edge-pkgs.iw # replacement of wireless-tools(iwconfig)

      # Alt w3m
      # Do not install in dawin yet: https://github.com/NixOS/nixpkgs/blob/b4b293ec6c61e846d69224ea0637411283e2ad39/pkgs/by-name/ch/chawan/package.nix#L82
      # Keybindigs: https://git.sr.ht/~bptato/chawan/tree/master/item/res/config.toml
      chawan # `cha`

      homemade-pkgs.renmark # Depend on chawan
    ];

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
