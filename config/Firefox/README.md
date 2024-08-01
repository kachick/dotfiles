# Firefox

## How to know the config key?

1. Open `about:config`
1. Check `Display only changed flags` (I don't know the original English message)
1. Modify config with `about:preferences`
1. Check `about:config` again

And <https://github.com/yokoffing/Betterfox/blob/> helps to know the overview.

## How to change finder in page position from bottom to top?

In Nix, we can define this step with <https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/firefox.nix>

1. `about:config`
1. Enable `toolkit.legacyUserProfileCustomizations.stylesheets`
1. Get profile folder path from `about:support`
1. Put [userChrome.css](userChrome.css) in the profile folder
1. Restart Firefox
