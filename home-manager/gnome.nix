{ lib, pkgs, ... }:

let
  spotify-pwa-file = "chrome-pjibgclleladliembfgfagdaldikeohf-Default.desktop";
in
{
  xdg.dataFile."applications/${spotify-pwa-file}".source = ../config/pwa/spotify.desktop;

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/misc/dconf.nix
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
            pop-shell
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
            xremap
          ]
        );

        favorite-apps = [
          "Alacritty.desktop"
          "kitty.desktop"
          "dev.zed.Zed.desktop"
          "firefox.desktop"
          "io.gitlab.news_flash.NewsFlash.desktop"
          "org.gnome.Rhythmbox3.desktop"
          "org.gnome.Nautilus.desktop"
        ];
      };

      # https://unix.stackexchange.com/questions/481142/launch-default-terminal-emulator-by-command
      "org/gnome/desktop/default-applications/terminal" = {
        exec = lib.getExe pkgs.alacritty;
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

      "org/gnome/desktop/wm/preferences" = {
        num-workspaces = 3;
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
        # control-center = [ "<Super>comma" ]; # I set this because of inspired by vscode, but disable to avoid conflict of pop-shell minimizerr
        www = [ "<Super>w" ]; # Prefer w even through pop-shell recommends to Super+b
        home = [ ];
        email = [ ];
        # terminal = [ "<Super>t" ]; I don't know why this won't work. So use cosutom keybinding
        search = [ "<Super>f" ]; # pop-shell sets to file manager, but replace to overview
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Alacritty";
        binding = "<Super>t";
        command = lib.getExe pkgs.alacritty;
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "Resource Monitor - TUI";
        binding = "<Super>r";
        # https://askubuntu.com/questions/5172/running-a-desktop-file-in-the-terminal
        command = "gtk-launch btop.desktop";
      };

      # https://github.com/pop-os/shell/blob/master_noble/schemas/org.gnome.shell.extensions.pop-shell.gschema.xml
      "org/gnome/shell/extensions/pop-shell" = {
        tile-by-default = true;

        # Keybindings: https://github.com/pop-os/shell/blob/master_noble/scripts/configure.sh

        # https://www.reddit.com/r/pop_os/comments/mt5kgf/how_to_change_default_keybind_for/
        activate-launcher = [ "<Alt>space" ];

        active-hint = true;
      };

      "org/gnome/shell/extensions/clipboard-history" = {
        history-size = 100;
        toggle-menu = [ "<Super>v" ]; # default: ['<Super><Shift>v']
        cache-only-favorites = true;
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
        # The feature is useful, but frustrated when using pop-shell shortcuts. Super modifier is mostly used now
        overlay-key = "";
      };

      "org/gnome/mutter/keybindings" = {
        toggle-tiled-left = [ ];
        toggle-tiled-right = [ ];
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
      };

      "org/gnome/shell/extensions/auto-move-windows" = {
        application-list = [
          "dev.zed.Zed.desktop:2"
          # TODO: Add vscode here as zed-editor
          "${spotify-pwa-file}:3"
          "org.gnome.Rhythmbox3.desktop:3"
        ];
      };

      "org/virt-manager/virt-manager/connections" = {
        autoconnect = [ "qemu:///system" ];
        uris = [ "qemu:///system" ];
      };

      # https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland
      "org.gnome.settings-daemon.plugins.xsettings" = {
        overrides = "{'Gtk/IMModule':<'fcitx'>}";
      };
    };
  };
}
