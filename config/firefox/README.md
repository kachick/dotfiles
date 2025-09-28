# Firefox Customization Guide

This document provides tips for advanced customization of Firefox.

---

### How do I find the name of a configuration key?

To identify the `about:config` key associated with a setting in the preferences UI:

1. Open a new tab and navigate to `about:config`.
2. Search for the `showOnlyModified` preference and set it to `true`. This will filter the list to show only settings that have been changed from their default values.
3. Open `about:preferences` (the standard settings UI) in another tab and change the setting you are interested in.
4. Switch back to the `about:config` tab. The key for the setting you just changed should now appear in the filtered list.

For a comprehensive overview of privacy and performance-related settings, the [Betterfox project](https://github.com/yokoffing/Betterfox/) is an excellent resource.

### How do I move the in-page search bar to the top?

This requires using a custom `userChrome.css` file.

1. **Enable Custom Stylesheets:**
   - Go to `about:config`.
   - Search for `toolkit.legacyUserProfileCustomizations.stylesheets` and set it to `true`.

2. **Locate Your Profile Directory:**
   - Go to `about:support`.
   - Find the "Profile Directory" entry and click the "Open Directory" button.

3. **Apply the Custom CSS:**
   - Inside your profile directory, create a new folder named `chrome`.
   - Place the [`userChrome.css`](./userChrome.css) file from this repository into the `chrome` folder.

4. **Restart Firefox** to apply the changes.

**Note for Nix users:** This can also be managed declaratively using the [Home Manager Firefox module](https://github.com/nix-community/home-manager/blob/master/modules/programs/firefox.nix).

### How do I modify or disable built-in keybindings?

Modifying some of Firefox's hardcoded keybindings is not straightforward and may require patching the source code.

- **Source Code References:**
  - [browser.xhtml](https://searchfox.org/mozilla-central/rev/03258de701dbcde998cfb07f75dce2b7d8fdbe20/browser/base/content/browser.xhtml#146-147)
  - [browser-sets.inc](https://searchfox.org/mozilla-central/rev/03258de701dbcde998cfb07f75dce2b7d8fdbe20/browser/base/content/browser-sets.inc#166)

Given the difficulty, it may be more practical to learn and adapt to the default Firefox keybindings, especially if you use a keyboard-driven workflow (e.g., with a tiling window manager).

- [Official Keyboard Shortcuts (Mozilla Support)](https://support.mozilla.org/en-US/kb/keyboard-shortcuts-perform-firefox-tasks-quickly)
