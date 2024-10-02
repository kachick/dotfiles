{ lib, pkgs, ... }:

lib.mkMerge [
  # Firefox package does not support both M1 and Intel like x86_64-apple-darwin
  (lib.mkIf pkgs.stdenv.isLinux {
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

          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false; # `Sponsored shortcuts`
          "browser.newtabpage.activity-stream.showSponsored" = false;

          "browser.quitShortcut.disabled" = true;
          "browser.warnOnQuitShortcut" = true; # By default true, just ensuring

          "layout.spellcheckDefault" = true;
        };
        userChrome = builtins.readFile ../config/firefox/userChrome.css;
      };
    };
  })
]
