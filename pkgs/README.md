# Packages in this repository

This directory contains Nix package definitions, organized by their origin and purpose.

## Directory Structure

- `by-name/`: Packages where the source code is managed in this repository, organized in nixpkgs standard by-name structure (`by-name/<2-prefix>/<pname>`).
  - Examples: `la`, `lat`, `tanuki-hao`, `lima-full`.
  - Exposed as: `pkgs.local.<name>`.
- `pinned/`: (Virtual/Implicit) External packages from `nixpkgs` or other flakes that are explicitly built and cached in CI, often for stability or specific versioning.
  - Examples: `zed-editor`, `kanata-tray`.
  - Exposed as: `pkgs.pinned.<name>` (or directly in `packages` output).
- `list.toml`: Metadata for CI builds and automated updates (e.g., build/test flags and `nix-update` targets). Workflows sync with this file via `go run ./cmd/ci-build sync-workflows`.

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

Packages exposed in `packages` output can be updated using standard CLI tools:

- **Hash Update**: For Go/Rust packages where dependabot only updates `go.mod` or `Cargo.toml`, use:

  ```console
  nix-update --flake pname --version=skip
  ```

- Automated version updates are configured in `pkgs/list.toml` and run via GitHub Actions.

## Why the `by-name` layout

`pkgs/by-name/` follows the standard `nixpkgs` layout (`by-name/<2-prefix>/<pname>/package.nix`).

When testing tools from the Nix ecosystem (such as `nix-update`, `nixpkgs-vet`, or `nixpkgs-hammering`), some of them expected the directory tree to follow the `nixpkgs` structure. Keeping this layout allows these tools to work without extra setup.

## Why not publish to NUR

This repository does not publish packages to the [Nix User Repository (NUR)](https://github.com/nix-community/NUR):

- NUR only checks evaluation. It does not run full builds or host binary caches. This repository wants to run rich CI builds with tests and push results to Cachix.
- NUR asks to keep repositories small ("Keep your repositories slim") for its evaluator. This repository maintains many CI workflows to test packages and verify that they work inside Home Manager and NixOS configurations. A minimal repository structure does not fit this heavy testing setup alongside dotfiles, system configs, and Go tools.
- Calling packages directly with `nix run github:kachick/dotfiles#<pname>` or using the Flake inputs works well without an external index.

## Why `nixpkgs-vet` is not enforced

Although `pkgs/by-name/` follows the standard `nixpkgs` layout (`by-name/<2-prefix>/<pname>`), `nixpkgs-vet` is not enforced in CI.

`nixpkgs-vet` strictly forbids packages from referencing files outside their package directory (rule `NPV-123`). In this monorepo, local packages intentionally share top-level resources such as `go.mod`, `internal/`, and shared configuration files under `config/` (via relative paths like `../../../../.`). Restructuring packages to satisfy `nixpkgs-vet` would require duplicating shared files or splitting Go modules, which conflicts with this monorepo design.
