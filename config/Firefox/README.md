# Firefox

## How to change finder in page position from bottom to top?

In Nix, we can define this step with https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/firefox.nix

1. `about:config`
1. Enable `toolkit.legacyUserProfileCustomizations.stylesheets`
1. Get profile folder path from `about:support`
1. Put [userChrome.css](userChrome.css) in the profile folder
1. Restart Firefox
