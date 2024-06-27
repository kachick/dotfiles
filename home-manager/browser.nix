{ ... }:

{
  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/firefox.nix
  programs.firefox = {
    enable = true;
    profiles.default = {
      isDefault = true;
      settings = {
        # UI lang
        "intl.locale.requested" = "ja";

        "browser.shell.checkDefaultBrowser" = false;

        # Required for playing DRM contents as Spotify
        "media.eme.enabled" = true;

        # Enabling userChrome.css
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # Disabling alt+ keybinds for lanchers
        # https://www.reddit.com/r/firefox/comments/129w85w/is_there_a_way_to_disable_firefox_alt_keyboard/
        "ui.key.menuAccessKeyFocuses" = false;
      };
      userChrome = builtins.readFile ../config/Firefox/userChrome.css;
    };
  };

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/chromium.nix
  programs.google-chrome = {
    enable = true;
    # https://wiki.archlinux.org/title/Chromium#Native_Wayland_support
    commandLineArgs = [ "--enable-wayland-ime" ];
  };
}
