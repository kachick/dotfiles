# dependencies

## Why

- Avoid loading packages for just getting the completions in shell rc build steps too keep faster
- These paths are not ensured in nix. So it might be broken if the package or upstream changed the filenames

## How

- Avoid `vendor` for this dirname while using golang
- They might be different result with actually using. Prefer Linux rather than Darwin when select a channel
- Keep convention the filenames for easy use of `source`
