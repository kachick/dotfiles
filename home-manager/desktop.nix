{
  lib,
  #  pkgs,
  ...
}:

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
    #   - Such as files in ~/.local/share/applications by GNOME default as written in https://askubuntu.com/questions/117341/how-can-i-find-desktop-files, however this module does not put on there
    #
    # - Required to install PWA itself from browser even if activated these shortcuts. However this definition is also required to share the desktop file in all NixOS device
    # - Required to log-out from GNOME to apply in overview
    # - Duplicate icons will be listed in overview for the original PWA and this wrapper. So adding in dock would be better to avoid confusions
    #
    # - What is the StartupWMClass?: https://askubuntu.com/questions/367396/what-does-the-startupwmclass-field-of-a-desktop-file-represent
    # - How to get WM_CLASS on wayland?: Use lg(Looking Glass). See https://askubuntu.com/a/1468539
    #
    # Chrome originally sets the icon like `Icon=chrome-${app_id}-${profile_index (replaced space with _)}`, however it will not fit for managing by home-manager
    # So manually setting the icon here
    # Icons are defined in PWA manifest, it is specified in their <link> tag. https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Manifest/Reference/icons
    #
    # Prefer url(app) instead of PWA(app-id) to avoid chrome profile number problem
    #
    # Don't quotate with 'content' in the desktop entry. Use "content"
    # desktopEntries = {
    #   youtube-music-pwa = rec {
    #     exec = ''
    #       ${lib.getExe pkgs.my.chrome-with-profile-by-name} personal --app="https://music.youtube.com/"
    #     '';
    #     name = "YouTube_Music";
    #     settings = {
    #       StartupWMClass = name;
    #     };
    #     # https://music.youtube.com/manifest.webmanifest
    #     icon = "${pkgs.fetchurl {
    #       url = "https://www.gstatic.com/youtube/media/ytm/images/applauncher/cairo/music_icon_512x512.png";
    #       hash = "sha256-h51FhG7ouDqaz03Q6SK/Qs2XRhpIOQL/SwkltjmrnYQ=";
    #     }}";
    #   };

    #   # Amazon Music does not officially support PWA. However it is almost working.
    #   amazon-music-pwa = rec {
    #     exec = ''
    #       ${lib.getExe pkgs.my.chrome-with-profile-by-name} personal --app="https://music.amazon.co.jp/"
    #     '';
    #     name = "Amazon_Music";
    #     settings = {
    #       StartupWMClass = name;
    #     };
    #     icon = "${pkgs.fetchurl {
    #       # Using different domain. However this URL was got from <link> tag in https://music.amazon.co.jp
    #       url = "https://d5fx445wy2wpk.cloudfront.net/icons/amznMusic_favicon.png";
    #       hash = "sha256-BH//RZsuRVa4QoxAiL55iOEVftNYCljbsDjFLIZLIjs=";
    #     }}";
    #   };

    #   spotify-pwa = rec {
    #     exec = ''
    #       ${lib.getExe pkgs.my.chrome-with-profile-by-name} personal --app="https://open.spotify.com/"
    #     '';
    #     name = "Spotify";
    #     settings = {
    #       StartupWMClass = name;
    #     };
    #     # It might be unstable with the their CDN URL
    #     icon = "${pkgs.fetchurl {
    #       url = "https://open.spotifycdn.com/cdn/images/icons/Spotify_512.7e07796d.png";
    #       hash = "sha256-fgd5bZ+qDCkeJQYNLRQJo1WKUBHGaoufVhlkC8PLR+0=";
    #     }}";
    #   };
    # };
  };
}
