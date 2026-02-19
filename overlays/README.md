# Overlays

This directory manages Nix overlays to extend or modify `nixpkgs`.

## Structure

- `default.nix`: The entry point that imports all other overlays.
- `overrides/`: Overlays that modify existing packages in `nixpkgs`.
- `patched/`: Overlays for custom or heavily patched packages.
- `unstable.nix`: Provides access to the `unstable` channel via `pkgs.unstable`.
- `my.nix`: Imports local packages from the `pkgs/` directory.

## How it works (and why it's safe)

We use a "directory-based automatic loading" system in `overrides/` and `patched/`.

### Automatic Loading

The `default.nix` in each subdirectory uses `builtins.readDir` to find all `.nix` files and load them automatically. You can add a new override by simply creating a new `.nix` file in the appropriate directory.

### Avoiding Infinite Recursion

We use `prev.lib` instead of `final.lib` for the loading logic.
Nix calculates the "names" of packages before their "values".

1. **Discovery (Names)**: We get package names from filenames using `builtins.readDir`. This does NOT use `final`, so it's safe from loops.
2. **Evaluation (Values)**: We use `final` inside `callPackage` to get the latest dependencies.

## Tips

### Overriding non-mkDerivation packages

Overriding non `mkDerivation` packages (like those using `buildRustPackage` or `buildNpmPackage`) often makes it hard to modify the hash (not just the source hash). In such cases, you might need to override the specific builder attributes or use a more manual approach.

- Rust:
  - https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/20
  - https://discourse.nixos.org/t/nixpkgs-overlay-for-mpd-discord-rpc-is-no-longer-working/59982/2
- npm: https://discourse.nixos.org/t/npmdepshash-override-what-am-i-missing-please/50967/4
