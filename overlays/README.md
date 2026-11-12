# Overlays

- `local.nix`: Exposes `pkgs/by-name/` under `pkgs.local`.
- `pinned.nix`: Exposes external flake inputs under `pkgs.pinned`.
- `overrides/`: Overrides upstream `nixpkgs` names only when a system module requires a fixed attribute name (e.g., `mozc` for IBus). Everything else uses `pkgs.local` or `pkgs.pinned` to avoid name collisions.

## Implementation Notes

- `overrides/default.nix` discovers filenames with `builtins.readDir` and `prev.lib` (avoiding infinite recursion on `final`), then evaluates each package with `final.callPackage`.
- Overriding hashes in language-specific builders:
  - Rust: [Discourse 4393](https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/20), [Discourse 59982](https://discourse.nixos.org/t/nixpkgs-overlay-for-mpd-discord-rpc-is-no-longer-working/59982/2)
  - npm: [Discourse 50967](https://discourse.nixos.org/t/npmdepshash-override-what-am-i-missing-please/50967/4)
