{ lib, pkgs, ... }:

let
  defaultBrowser = [
    "google-chrome.desktop"
    "firefox.desktop"
  ];

  # Loupe is faster than browsers to open images
  imageViewer = [
    # https://gitlab.gnome.org/GNOME/loupe/-/blob/47.2/data/meson.build#L54
    "org.gnome.Loupe.desktop"
  ];
in
{
  imports = [ ./gnome.nix ];

  xdg = {
    # https://github.com/nix-community/home-manager/blob/release-24.11/modules/misc/xdg-mime-apps.nix - different of  https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/config/xdg/mime.nix
    mimeApps = {
      enable = true;
      # Don't use `xdg-settings set default-web-browser`.
      # https://github.com/nix-community/home-manager/issues/96#issuecomment-343650659 is old. Using both made errors such as https://github.com/kachick/dotfiles/pull/1038#discussion_r1910360832
      # So use only xdg.mimeApps
      defaultApplications =
        (lib.genAttrs [
          "text/html"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
          "x-scheme-handler/about"
          "x-scheme-handler/unknown"
          "application/pdf" # I prefer to open PDF with reader, editor is not frequently used. And native readers Papers is much heavy than browsers
        ] (_: defaultBrowser))
        // (lib.genAttrs [
          # Supported mime-types: https://gitlab.gnome.org/GNOME/loupe/-/blob/47.2/data/meson.build

          "image/jpeg"
          "image/png"
          "image/gif"
          "image/webp"
          "image/tiff"
          "image/bmp"
          "image/vnd.microsoft.icon"
          "image/svg+xml"
          "image/svg+xml-compressed"
        ] (_: imageViewer));
    };

    # - Related Modules:
    #   - https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/build-support/make-desktopitem/default.nix
    #   - https://github.com/nix-community/home-manager/blob/release-24.11/modules/misc/xdg-desktop-entries.nix
    # - Put in ~/.local/share/applications
    #   See https://askubuntu.com/questions/117341/how-can-i-find-desktop-files
    #
    # What is the StartupWMClass?: https://askubuntu.com/questions/367396/what-does-the-startupwmclass-field-of-a-desktop-file-represent
    desktopEntries = {
      youtube-music-pwa =
        let
          app-id = "cinhimbnkkaeohfgghhklpknlkffjgod";
        in
        {
          exec = ''
            ${lib.getExe pkgs.my.chrome-with-profile-by-name} personal --app-id=${app-id}
          '';
          name = "YouTube Music";
        };

      amazon-music-pwa =
        let
          app-id = "dojpeppajphepagdhclblkkjnoaeamee";
        in
        {
          exec = ''
            ${lib.getExe pkgs.my.chrome-with-profile-by-name} personal --app-id=${app-id}
          '';
          name = "Amazon Music";
        };
    };
  };
}
