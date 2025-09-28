# Custom Packages

This directory contains several types of packages:

- Small, custom tools that may be rewritten in other languages in the future.
- Nix packages that are not yet available in the main [NixOS/nixpkgs](https://github.com/NixOS/nixpkgs) repository.
- Scripts that act as aliases across multiple shells, for cases where a native shell alias is not suitable.

## Development Guidelines

Follow these guidelines when adding or modifying packages.

### Scripts

- **Shebangs:** Do not add a shebang (e.g., `#!/bin/bash`) to your script files. The correct interpreter will be set by `pkgs.writeShellApplication` in the Nix expression.
- **Implementation:** Avoid implementing complex or non-trivial scripts directly within a `.nix` file. Keeping them in separate script files allows for better editor and formatter support.

### Nix Expressions

- **`pkgs/default.nix`:** Do not implement packages directly in this file. It should remain a simple list of package definitions to keep it clean and readable.
- **`fileset`:** Avoid using `fileset.gitTracked .` as it will cause packages to rebuild unnecessarily whenever any tracked file (like this `README.md`) changes.
- **`nix-update`:** Currently, do not use `fileset.gitTracked` as it is not yet supported by `nix-update`. See [this issue](https://github.com/Mic92/nix-update/issues/335) for details.

## Updating Packages

- **Automation:** There are currently no plans to automate version updates for these packages.
- **Dependabot:** For Go and Rust packages, Dependabot pull requests that update dependencies will also change the package hash. To handle this, the hash can be updated using `nix-update --flake <pname> --version=skip`.
