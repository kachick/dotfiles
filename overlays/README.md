# Overlays in this repository

This directory contains Nixpkgs overlays used to customize, fix, or extend the default package set.

## Directory Structure

- `default.nix`: The entry point that imports all other overlays.
- `local.nix`: Exposes packages defined in `pkgs/local/` under the `pkgs.local` namespace.
- `pinned.nix`: Explicitly exposes and pins specific external packages (e.g., from `nixpkgs-unstable` or external flake inputs) under the `pkgs.pinned` namespace.
- `unstable.nix`: Imports and exposes the `nixpkgs-unstable` channel as `pkgs.unstable`.
- `overrides/`: Contains transparent overlays that override existing package names in `nixpkgs` (e.g., `mozc`).

## Guidelines

1. **Namespace Separation**: Use `local` and `pinned` to avoid accidental collisions with upstream `nixpkgs`.
2. **Transparent Overlays**: Only use these in `overrides/` when a system component expects a specific name and cannot be configured otherwise.
3. **Automatic Loading**: The `default.nix` in `overrides/` uses `builtins.readDir` to find and load all `.nix` files automatically.

## How it works (and why it's safe)

We use `prev.lib` instead of `final.lib` for the loading logic to avoid infinite recursion. Nix calculates the "names" of packages before their "values".

1. **Discovery (Names)**: We get package names from filenames using `builtins.readDir`. This does NOT use `final`, so it's safe from loops.
2. **Evaluation (Values)**: We use `final` inside `callPackage` to get the latest dependencies.

## Tips

### Overriding non-mkDerivation packages

Overriding non `mkDerivation` packages (like those using `buildRustPackage` or `buildNpmPackage`) often makes it hard to modify the hash (not just the source hash). In such cases, you might need to override the specific builder attributes or use a more manual approach.

- Rust:
  - <https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/20>
  - <https://discourse.nixos.org/t/nixpkgs-overlay-for-mpd-discord-rpc-is-no-longer-working/59982/2>
- npm: <https://discourse.nixos.org/t/npmdepshash-override-what-am-i-missing-please/50967/4>
