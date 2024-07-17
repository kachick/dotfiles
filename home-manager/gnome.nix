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
      "org/gnome/shell/extensions/pop-shell" = {
        tile-by-default = true;
      };
    };
  };
}
