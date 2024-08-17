# Firefox

## How to know the config key?

1. Open `about:config`
1. Check `Display only changed flags` (I don't know the original English message)
1. Modify config with `about:preferences`
1. Open `about:config` again

And <https://github.com/yokoffing/Betterfox/blob/> helps to know the overview.

## How to change finder in page position from bottom to top?

In Nix, we can define this step with <https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/firefox.nix>

1. `about:config`
1. Enable `toolkit.legacyUserProfileCustomizations.stylesheets`
1. Get profile folder path from `about:support`
1. Put [userChrome.css](userChrome.css) in the profile folder
1. Restart Firefox

## How to modify or disable keybinding?

Some of them needs to be resolved in patch

- <https://searchfox.org/mozilla-central/rev/03258de701dbcde998cfb07f75dce2b7d8fdbe20/browser/base/content/browser.xhtml#146-147>
- <https://searchfox.org/mozilla-central/rev/03258de701dbcde998cfb07f75dce2b7d8fdbe20/browser/base/content/browser-sets.inc#166>

However, if you are preferring keyboard operations such as tilling window manager, accepting Firefox keybinds maybe reasonable choice for now...

- [Keyboard shortcuts(ja)](https://support.mozilla.org/ja/kb/keyboard-shortcuts-perform-firefox-tasks-quickly#w_twindowtotabu)
