{
  lib,
  pkgs,
  edge-pkgs,
  ...
}:

{
  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/misc/dconf.nix
  dconf = {
    enable = true;
    settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = with pkgs.gnomeExtensions; [
          appindicator.extensionUuid
          blur-my-shell.extensionUuid
          pop-shell.extensionUuid
          clipboard-history.extensionUuid
          kimpanel.extensionUuid
          edge-pkgs.gnomeExtensions.rclone-manager.extensionUuid
        ];

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
