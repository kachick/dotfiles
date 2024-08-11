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

## How to modify keybinding?

Some of them needs to be resolved in patch

<https://searchfox.org/mozilla-central/rev/03258de701dbcde998cfb07f75dce2b7d8fdbe20/browser/base/content/browser.xhtml#146-147>
<https://searchfox.org/mozilla-central/rev/03258de701dbcde998cfb07f75dce2b7d8fdbe20/browser/base/content/browser-sets.inc#166>

1. `curl -L https://hg.mozilla.org/mozilla-central/raw-file/tip/browser/base/content/browser-sets.inc > config/Firefox/browser-sets.inc`
1. `cp config/Firefox/browser-sets.inc config/Firefox/browser-sets.my.inc`
1. `micro config/Firefox/browser-sets.my.inc`
1. `diff -Naur config/Firefox/browser-sets.inc config/Firefox/browser-sets.my.inc > config/Firefox/browser-sets.inc.patch`
1. `gitleaks detect --no-git` may detect the original *.inc files, then remove and check again
