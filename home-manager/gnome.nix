{
  lib,
  pkgs,
  edge-pkgs,
  ...
}:

{
  # https://github.com/germanztz/gnome-shell-extension-rclone-manager attempt to decrypt the config file via `--password-command` by default
  # And it uses `echo` in the implementation, NixOS does not have /bin/echo and printing the secret does not make sense to me...
  # And it does not have the feature to specify environments. So needed to set here
  # https://github.com/germanztz/gnome-shell-extension-rclone-manager/blob/72f1a2ac4a1205069bc2bda5d1e5906e83a2b4ab/fileMonitorHelper.js#L124-L126
  # https://github.com/germanztz/gnome-shell-extension-rclone-manager/blob/72f1a2ac4a1205069bc2bda5d1e5906e83a2b4ab/fileMonitorHelper.js#L594
  home.file.".gnomerc".text = ''
    export RCLONE_CONFIG_PASS="$(${lib.getExe pkgs.micro})"
  '';

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/misc/dconf.nix
  dconf = {
    enable = true;
    settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;

        # Why needed an empty list?
        # I don't know why Gnome have both disabled and enabled, but disabled by settings menu inserts here and it ignores enabled-extensions...
        disabled-extensions = [ ];

        enabled-extensions =
          map (ext: ext.extensionUuid) (
            with pkgs.gnomeExtensions;
            [
              appindicator
              blur-my-shell
              pop-shell
              clipboard-history
              kimpanel
              removable-drive-menu
              system-monitor
              places-status-indicator
              window-list
              workspace-indicator
              applications-menu
              auto-move-windows
            ]
          )
          ++ [ edge-pkgs.gnomeExtensions.rclone-manager.extensionUuid ];

        favorite-apps = [
          "Alacritty.desktop"
          "dev.zed.Zed.desktop"
          "org.gnome.Nautilus.desktop"
          "firefox.desktop"
        ];
      };

      "org/gnome/desktop/wm/keybindings" = {
        toggle-message-tray = [ "<Shift><Super>m" ]; # default: ['<Super>v', '<Super>m'], `"disable"` restore default. So added annoy modifier to prevent trigger
      };

      "org/gnome/settings-daemon/plugins/media-keys" = {
        control-center = [ "<Super>comma" ];
        www = [ "<Super>w" ];
        search = [ "<Super>f" ];
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Terminal";
        binding = "<Super>t";
        command = lib.getExe pkgs.alacritty;
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "Resource Monitor - TUI";
        binding = "<Super>b"; # I don't know why, <Super>m don't work even if removed other shortcuts :<
        command = "${lib.getExe pkgs.alacritty} --command=${lib.getExe pkgs.bottom} --title='Resource Monitor(btm)'";
      };

      "org/gnome/shell/extensions/pop-shell" = {
        tile-by-default = true;
      };

      "org/gnome/shell/extensions/clipboard-history" = {
        history-size = 100;
        toggle-menu = [ "<Super>v" ]; # default: ['<Super><Shift>v']
      };

      "org/gnome/mutter" = {
        experimental-features = [ "scale-monitor-framebuffer" ];
      };
    };
  };
}
