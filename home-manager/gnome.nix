{ pkgs, ... }:

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
        ];
      };

      "org/gnome/desktop/wm/keybindings" = {
        toggle-message-tray = [ "<Super>m" ]; # default: ['<Super>v', '<Super>m']
      };

      "org/gnome/shell/extensions/pop-shell" = {
        tile-by-default = true;
      };

      "org/gnome/shell/extensions/clipboard-history" = {
        history-size = 100;
        toggle-menu = [ "<Super>v" ]; # default: ['<Super><Shift>v']
      };
    };
  };
}
