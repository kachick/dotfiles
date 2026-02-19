# Overlays

This directory manages Nix overlays to extend or modify `nixpkgs`.

## Structure

- `default.nix`: The entry point that imports all other overlays.
- `overrides/`: Overlays that modify existing packages in `nixpkgs` (e.g., `mozc`, `inetutils`).
- `patched/`: Overlays for custom or heavily patched packages (e.g., `gemini-cli-bin`, `rclone`).
- `unstable.nix`: Provides access to the `unstable` channel via `pkgs.unstable`.
- `my.nix`: Imports local packages from the `pkgs/` directory.

## How it works (and why it's safe)

We use a "directory-based automatic loading" system in `overrides/` and `patched/`.

### Automatic Loading

The `default.nix` in each subdirectory uses `builtins.readDir` to find all `.nix` files and load them automatically. You can add a new override by simply creating a new `pname.nix` file.

### Avoiding Infinite Recursion

We use `prev.lib` instead of `final.lib` for the loading logic.
Nix calculates the "names" of packages before their "values".

1. **Discovery (Names)**: We get package names from filenames using `builtins.readDir`. This does NOT use `final`, so it's safe from loops.
2. **Evaluation (Values)**: We use `final` inside `callPackage` to get the latest dependencies.

### callPackage Scope

Each `.nix` file (e.g., `mozc.nix`) is a function. We provide a rich scope via `callPackage`:

- `prev`: The original package set (useful for `prev.pname.overrideAttrs`).
- `final`: The latest package set after all overlays.
- Other inputs: Like `unstable` or `home-manager-linux`.

This setup is clean, easy to expand, and avoids common Nix pitfalls.
