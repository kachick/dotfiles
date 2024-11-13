{ ... }:
{
  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/firefox.nix
  programs.firefox = {
    enable = true;
    # In firefox package, use null instead of `pkgs.emptyDirectory`
    #   - https://github.com/kachick/dotfiles/pull/835#discussion_r1796307643
    #   - https://github.com/nix-community/home-manager/blob/342a1d682386d3a1d74f9555cb327f2f311dda6e/modules/programs/firefox/mkFirefoxModule.nix#L264
    package = null;
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
}
