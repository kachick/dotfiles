{ lib, pkgs, ... }:

{
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
            # paperwm # Don't use this extension, it might made crashes. See GH-1114
            clipboard-history
            removable-drive-menu
            # system-monitor
            places-status-indicator
            # window-list # Unnecessary since customized dock
            workspace-indicator
            applications-menu
            auto-move-windows
            # just-perfection # Don't use this extension, it made crashes. See GH-1114. And it always displays donation pop-up after updating
            dash-to-dock
            # Don't use third party themes. See https://github.com/do-not-theme/do-not-theme.github.io for detail
            # user-themes # the package name is not the `user-theme`, required `s` suffix
          ]
        );

        # - Might be needed to reboot to enable icons
        # - Using fixed profile shortcut is difficult in chrome. So don't add PWA here. See GH-813 and GH-968 for detail.
        favorite-apps = [
          "com.mitchellh.ghostty.desktop"
          "org.gnome.TextEditor.desktop"
          "google-chrome.desktop"
          "signal.desktop"
          "io.gitlab.news_flash.NewsFlash.desktop"
          "org.gnome.Nautilus.desktop"
        ];
      };

      # https://unix.stackexchange.com/questions/481142/launch-default-terminal-emulator-by-command
      "org/gnome/desktop/default-applications/terminal" = {
        exec = lib.getExe pkgs.ghostty;
        # exec-arg="";
      };

      "org/gnome/desktop/background" = {
        picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/drool-l.svg";
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

      # Some keybindings should be put in org/gnome/mutter/keybindings instead
      "org/gnome/desktop/wm/keybindings" = {
        activate-window-menu = [ ]; # Disabling default `<Alt>space` to run launchers

        show-desktop = [ "<Super>d" ];

        close = [
          "<Super>q"
          "<Alt>F4"
        ];

        # Avoid confusion with harf resize bindings
        # And these are not useful since dropping pop-shell :<
        #
        # cycle-windows = [
        #   "<Super>Right"
        # ];

        # cycle-windows-backward = [
        #   "<Super>Left"
        # ];

        lower = [
          # Like Windows
          # https://superuser.com/a/189235/120469
          # https://unix.stackexchange.com/a/718284
          "<Alt>Escape"
        ];

        panel-run-dialog = [
          "<Alt>F2" # default
          "<Super>r"
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

        # Intentioanlly specifies same values as default. Because of it is flaky removed if using default.
        switch-input-source = [ "<Super>space" ];
        switch-input-source-backward = [ "<Shift><Super>space" ];
      };

      "org/gnome/settings-daemon/plugins/media-keys" = {
        www = [ "<Super>w" ];
        home = [ ];
        email = [ ];
        # search = [ "<Alt>space" ]; # Don't set this. It does not realize toggle feature such as PowerToys Run. Prefer overlay-key
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Terminal";
        binding = "<Super>t";
        command = lib.getExe pkgs.ghostty;
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "Toggle Launcher";
        binding = "<Alt>space";
        command = lib.getExe pkgs.my.toggle-wofi;
      };

      "org/gnome/shell/extensions/clipboard-history" = {
        history-size = 100;
        toggle-menu = [ "<Super>v" ]; # default: ['<Super><Shift>v']
        cache-only-favorites = true;
        display-mode = 0;
      };

      "org/gnome/mutter" = {
        experimental-features = [ "scale-monitor-framebuffer" ];

        dynamic-workspaces = false;

        # Disable overlay-key if using paperwm or pop-shell. Super modifier is mostly used in them
        # Disable default Super runs GNOME overview with search
        # https://ubuntuforums.org/showthread.php?t=2405352
        # However just removing is not enough. Search feature cannot toggle. Providing an overlay-key is still better than none.
        # This option does not accept combo like the "<Alt>Space"
        #
        # Why this value?
        # - Avoid default Super_L for mistyping.
        # - Alt_R is using for IME switcher
        # - Super_R is missing in my laptop, however it is just ignored in the device
        overlay-key = "Super_R";
      };

      "org/gnome/mutter/keybindings" = {
        toggle-tiled-right = [
          "<Shift><Super>Right"
        ];

        toggle-tiled-left = [
          "<Shift><Super>Left"
        ];
      };

      # TODO: Display current keyboard layout on GNOME
      # AFAIK, There is no reasonable indicatoor for displaying current xkb layouts on Wayland and ibus
      # And I dropped fcitx5 in GH-1128 ...
      # https://github.com/zen-tools/gxkb made segfault
      # switch-input-source keybindings does not help this, indicator should be better and the launcher truncate mozc names
      "org/gnome/desktop/input-sources" = {
        sources = with lib.hm.gvariant; [
          (mkTuple [
            "ibus"
            "mozc-jp-ansi"
          ])
          (mkTuple [
            "ibus"
            "mozc-jp-jis"
          ])
        ];

        per-window = false;
      };

      "org/gnome/desktop/interface" = {
        # https://askubuntu.com/questions/701592/how-do-i-disable-activities-hot-corner-in-gnome-shell
        enable-hot-corners = false;

        # https://unix.stackexchange.com/questions/327975/how-to-change-the-gnome-panel-time-format
        clock-show-weekday = true;
      };

      "org/gnome/shell/extensions/dash-to-dock" = {
        # Should be disabled to avoid conflicting keybinds against <Super>Number workspace switcher
        hot-keys = false;

        dock-position = "BOTTOM";

        dock-fixed = true;
        icon-size-fixed = true;
        dash-max-icon-size = 24;
        extend-height = true;
        always-center-icons = true;
        custom-theme-shrink = true;
        show-show-apps-button = true;
        apply-custom-theme = true; # The description `uses built-in theme`. Confised with the option name...
        click-action = "previews"; # Most similar behavior like Windows. Without this, using window-list might be better

        multi-monitor = true;

        scroll-action = "switch-workspace";
      };

      "org/gnome/desktop/wm/preferences" = {
        num-workspaces = 3;
        workspace-names = [
          "Main"
          "Sandbox"
          "Music"
        ];
      };

      "org/gnome/shell/extensions/workspace-indicator" = {
        embed-previews = false;
      };

      "org/gnome/shell/extensions/auto-move-windows" = {
        application-list =
          let
            music = "3";
          in
          [
            "org.gnome.Rhythmbox3.desktop:${music}"
          ];
      };

      "org/gnome/nautilus/list-view" = {
        use-tree-view = true;
      };

      "org/gnome/nautilus/preferences" = {
        show-create-link = true;
      };
    };
  };
}
