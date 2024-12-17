{ lib, pkgs, ... }:

let
  spotify-pwa-file = "chrome-pjibgclleladliembfgfagdaldikeohf-Default.desktop";
  amazon_music-pwa-file = "chrome-dojpeppajphepagdhclblkkjnoaeamee-Profile_1.desktop";
in
{
  xdg.dataFile."applications/${spotify-pwa-file}".source = ../config/pwa/spotify.desktop;
  xdg.dataFile."applications/${amazon_music-pwa-file}".source = ../config/pwa/amazon_music.desktop;

  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/misc/dconf.nix
  dconf = {
    enable = true;
    settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;

        # Why needed an empty list?
        # I don't know why Gnome have both disabled and enabled, but disabled by settings menu inserts here and it ignores enabled-extensions...
        disabled-extensions = [ ];

        enabled-extensions = map (ext: ext.extensionUuid) (
          with pkgs.gnomeExtensions;
          [
            appindicator
            # blur-my-shell # Don't use this extension, it often makes flicker. See GH-775
            paperwm
            clipboard-history
            kimpanel
            removable-drive-menu
            # system-monitor
            places-status-indicator
            # window-list
            workspace-indicator
            applications-menu
            auto-move-windows
            just-perfection
            dash-to-dock
            # color-picker # Don't enable by default. It conflicts with clipboard-history
          ]
        );

        favorite-apps = [
          "kitty.desktop"
          "dev.zed.Zed.desktop"
          "google-chrome.desktop"
          "podman-desktop.desktop"
          "io.gitlab.news_flash.NewsFlash.desktop"
          amazon_music-pwa-file
          "org.gnome.Rhythmbox3.desktop"
          "org.gnome.Nautilus.desktop"
        ];
      };

      # https://unix.stackexchange.com/questions/481142/launch-default-terminal-emulator-by-command
      "org/gnome/desktop/default-applications/terminal" = {
        exec = lib.getExe pkgs.kitty;
        # exec-arg="";
      };

      # gsettings list-recursively | grep -F "<Super>"
      # Disabling defaults to enable Suprt+num family will be used to switch workspaces
      # https://github.com/pop-os/shell/issues/142
      "org/gnome/shell/keybindings" = {
        switch-to-application-1 = [ ];
        switch-to-application-2 = [ ];
        switch-to-application-3 = [ ];
        switch-to-application-4 = [ ];
        switch-to-application-5 = [ ];
        switch-to-application-6 = [ ];
        switch-to-application-7 = [ ];
        switch-to-application-8 = [ ];
        switch-to-application-9 = [ ];

        open-new-window-application-1 = [ ];
        open-new-window-application-2 = [ ];
        open-new-window-application-3 = [ ];
        open-new-window-application-4 = [ ];
        open-new-window-application-5 = [ ];
        open-new-window-application-6 = [ ];
        open-new-window-application-7 = [ ];
        open-new-window-application-8 = [ ];
        open-new-window-application-9 = [ ];

        toggle-message-tray = [ "<Shift><Super>m" ]; # default: ['<Super>v', '<Super>m'], `"disable"` restore default. So added annoy modifier to prevent trigger
      };

      "org/gnome/desktop/wm/keybindings" = {
        activate-window-menu = [ ]; # Disabling default `<Alt>space` to run launchers

        close = [
          "<Super>q"
          "<Alt>F4"
        ];

        switch-to-workspace-down = [
          "<Primary><Super>Down"
          "<Primary><Super>j"
        ];

        switch-to-workspace-up = [
          "<Primary><Super>Up"
          "<Primary><Super>k"
        ];

        move-to-monitor-left = [ ];
        move-to-monitor-down = [ ];
        move-to-monitor-up = [ ];
        move-to-monitor-right = [ ];

        move-to-workspace-down = [ ];
        move-to-workspace-up = [ ];

        toggle-maximized = [ "<Super>m" ];
        maximize = [ ];
        unmaximize = [ ];
        minimize = [ "<Super>comma" ];

        switch-to-workspace-left = [ ];
        switch-to-workspace-right = [ ];

        switch-to-workspace-1 = [ "<Super>1" ];
        switch-to-workspace-2 = [ "<Super>2" ];
        switch-to-workspace-3 = [ "<Super>3" ];
        # switch-to-workspace-4 = [ "<Super>4" ];
        # switch-to-workspace-5 = [ "<Super>5" ];
        # switch-to-workspace-6 = [ "<Super>6" ];
        # switch-to-workspace-7 = [ "<Super>7" ];
        # switch-to-workspace-8 = [ "<Super>8" ];
        # switch-to-workspace-9 = [ "<Super>9" ];

        move-to-workspace-1 = [ "<Super><Shift>1" ];
        move-to-workspace-2 = [ "<Super><Shift>2" ];
        move-to-workspace-3 = [ "<Super><Shift>3" ];
        # move-to-workspace-4 = [ "<Super><Shift>4" ];
        # move-to-workspace-5 = [ "<Super><Shift>5" ];
        # move-to-workspace-6 = [ "<Super><Shift>6" ];
        # move-to-workspace-7 = [ "<Super><Shift>7" ];
        # move-to-workspace-8 = [ "<Super><Shift>8" ];
        # move-to-workspace-9 = [ "<Super><Shift>9" ];
      };

      "org/gnome/settings-daemon/plugins/media-keys" = {
        www = [ "<Super>w" ];
        home = [ ];
        email = [ ];
        search = [ "<Alt>space" ];
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Terminal";
        binding = "<Super>t";
        command = lib.getExe pkgs.kitty;
      };

      "org/gnome/shell/extensions/clipboard-history" = {
        history-size = 100;
        toggle-menu = [ "<Super>v" ]; # default: ['<Super><Shift>v']
        cache-only-favorites = true;
        display-mode = 0;
      };

      "org/gnome/shell/extensions/just-perfection" = {
        startup-status = 0;

        clock-menu-position = 1;
        clock-menu-position-offset = 15;
      };

      "org/gnome/mutter" = {
        experimental-features = [ "scale-monitor-framebuffer" ];

        dynamic-workspaces = false;

        # Disable default Super runs GNOME overview with search
        # https://ubuntuforums.org/showthread.php?t=2405352
        # The feature is useful, but frustrated when using paperwm or pop-shell shortcuts. Super modifier is mostly used in them
        overlay-key = "";
      };

      "org/gnome/mutter/keybindings" = {
        toggle-tiled-left = [ ];
        toggle-tiled-right = [ ];
      };

      "org/gnome/desktop/input-sources" = {
        sources = with lib.hm.gvariant; [
          (mkTuple [
            "xkb"
            "us"
          ])
          (mkTuple [
            "xkb"
            "jp"
          ])
        ];
      };

      "org/gnome/desktop/interface" = {
        # https://askubuntu.com/questions/701592/how-do-i-disable-activities-hot-corner-in-gnome-shell
        enable-hot-corners = false;

        # https://unix.stackexchange.com/questions/327975/how-to-change-the-gnome-panel-time-format
        clock-show-weekday = true;

        gtk-theme = "Nordic";
      };

      "org/gnome/shell/extensions/dash-to-dock" = {
        # Should be disabled to avoid conflicting keybinds against <Super>Number workspace switcher
        hot-keys = false;

        dock-position = "LEFT";

        dock-fixed = true;
        custom-theme-shrink = true;

        multi-monitor = true;
      };

      "org/gnome/desktop/wm/preferences" = {
        theme = "Nordic";

        num-workspaces = 3;
        # This names are might not be persisted with paperwm, it also uses own UUID for that
        workspace-names = [
          "Main"
          "Sandbox"
          "Music"
        ];
      };

      "org/gnome/shell/extensions/auto-move-windows" = {
        application-list = [
          "${spotify-pwa-file}:3"
          "${amazon_music-pwa-file}:3"
          "org.gnome.Rhythmbox3.desktop:3"
        ];
      };

      "org/gnome/shell/extensions/paperwm/keybindings" = {
        take-window = [ ]; # default: ['<Super>t']
        center-vertically = [ ]; # default: ['<Super>v']
        open-window-position = 0;
      };

      "org/virt-manager/virt-manager/connections" = {
        autoconnect = [ "qemu:///system" ];
        uris = [ "qemu:///system" ];
      };
    };
  };
}
