# Packages in this repository

This directory contains Nix package definitions, organized by their origin and purpose.

## Directory Structure

- `local/`: Packages where the source code is managed in this repository, or where we provide our own packaging logic (e.g., `default.nix`) for external sources not found in `nixpkgs`.
  - Examples: `la`, `lat`, `tanuki-hao`, `lima-full`.
  - Exposed as: `pkgs.local.<name>`.
- `pinned/`: (Virtual/Implicit) External packages from `nixpkgs` or other flakes that we explicitly want to build and cache in CI, often for stability or specific versioning.
  - Examples: `zed-editor`, `kanata-tray`.
  - Exposed as: `pkgs.pinned.<name>` (or directly in `packages` output).

## Principles

1. **Namespace Separation**: Use explicit namespaces (`local`, `pinned`, `unstable`) to avoid accidental name collisions with upstream `nixpkgs`.
2. **Transparency vs. Explicitness**:
   - Use **Transparent Overlays** only when an existing system component (like IBus) expects a specific name (e.g., `mozc`).
   - Use **Explicit Namespaces** for everything else to keep the origin of a package clear in the configuration files.
3. **CI Integration**: Packages listed in `packages` output of `flake.nix` are automatically built by the dedicated package workflows.

## Guidelines

- **Shebangs**: Do not apply shebangs manually in scripts; they will be applied by `pkgs.writeShellApplication`.
- **Implementation**:
  - Do not directly implement packaging in `default.nix` or `local.nix` to keep lists simple.
  - Do not directly implement non-tiny scripts in `*.nix` files to ensure better editor/formatter support.
- **Fileset Usage**:
  - Avoid `fileset.gitTracked root` as it triggers rebuilds even for unrelated changes (like `README.md`).
  - [nix-update does not yet support `fileset.gitTracked`](https://github.com/Mic92/nix-update/issues/335), so avoid using it if you need automated updates.

## How to update

Packages exposed in `packages` output can be updated using the standard CLI tools:

- **Hash Update**: For Go/Rust packages where dependabot only updates `go.mod` or `Cargo.toml`, use:

  ```console
  nix-update --flake pname --version=skip
  ```

- Automated version updates are not currently considered for these local packages.
