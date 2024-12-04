{ lib, pkgs, ... }:

{
  imports = [ ./gnome.nix ];

  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/home-environment.nix#
  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/lib/dag.nix
  home = {
    activation = {
      # defaultApplications in xdg=* modules do not support except mime types. So required this for hotkey use
      setDefaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run '${pkgs.xdg-utils}/bin/xdg-settings' set 'default-web-browser' 'google-chrome.desktop'
      '';
    };
  };

  xdg = {
    # https://github.com/nix-community/home-manager/blob/release-24.11/modules/misc/xdg-mime-apps.nix - different of  https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/config/xdg/mime.nix
    mimeApps = {
      enable = false; # Avoiding error: bin/xdg-mime: line 1002: hm_mimeapps.list.new: Read-only file system
      defaultApplications = {
        "application/pdf" = [
          "google-chrome.desktop"
          "firefox.desktop"
        ];
      };
    };
  };

  # Extracted from encryption.nix to avoid dbus error in GitHub hosted runner
  #
  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/services/pass-secret-service.nix
  # Make it possible to use libsecret which is required in vscode GitHub authentication(--password-store="gnome-libsecret"), without gnome-keyring(GH-814).
  #
  # Alternative candidates: https://github.com/grimsteel/pass-secret-service
  services.pass-secret-service.enable = true;
}
