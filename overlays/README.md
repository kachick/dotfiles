# Overlays in this repository

This directory contains Nixpkgs overlays used to customize, fix, or extend the default package set.

## Directory Structure

- `local.nix`: Exposes packages defined in `pkgs/local/` under the `pkgs.local` namespace.
- `pinned.nix`: Explicitly exposes and pins specific external packages (e.g., from `nixpkgs-unstable` or external flake inputs) under the `pkgs.pinned` namespace.
- `unstable.nix`: Imports and exposes the `nixpkgs-unstable` channel as `pkgs.unstable`.
- `overrides/`: Contains transparent overlays that override existing package names in `nixpkgs` (e.g., `mozc`).

## Guidelines

1. **Namespace Separation**: Use `local` and `pinned` to avoid accidental collisions with upstream `nixpkgs`.
2. **Transparent Overlays**: Only use these in `overrides/` when a system component expects a specific name and cannot be configured otherwise.
3. **Directory-based Automatic Loading**: Files in `overrides/` are automatically loaded and applied as overlays.
