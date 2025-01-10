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

    configFile =
      let
        pass-secret-service-service = pkgs.writeText "pass-secret-service-service" ''
          [Install]
          WantedBy=default.target

          ${builtins.readFile "${pkgs.my.pass-secret-service-rs}/share/systemd/user/pass-secret-service.service"}
        '';
      in
      {
        # Might be simplified if https://github.com/nix-community/home-manager/pull/4990 resolved
        "systemd/user/pass-secret-service.service".source = pass-secret-service-service;
        "systemd/user/default.target.wants/pass-secret-service.service".source =
          pass-secret-service-service;
      };

    # https://github.com/nix-community/home-manager/blob/d4aebb947a301b8da8654a804979a738c5c5da50/modules/services/pass-secret-service.nix#L67
    dataFile = {
      "dbus-1/services/org.freedesktop.secrets.service".source =
        "${pkgs.my.pass-secret-service-rs}/share/systemd/user/org.freedesktop.secrets.service";
    };
  };
}
