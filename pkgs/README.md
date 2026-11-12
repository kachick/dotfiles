# Packages

## Layout

- `by-name/<2-prefix>/<pname>/package.nix`: Local packages exposed as `pkgs.local.<name>`. Uses the `nixpkgs` `by-name` layout so tools like `nix-update` work without extra flags.
- `list.toml`: CI build, test, and `nix-update` metadata. Sync workflows with `task sync-workflows`.

## Guidelines

- Write scripts in separate files rather than inline Nix strings, and let `pkgs.writeShellApplication` generate shebangs.
- Avoid `fileset.gitTracked root` because it triggers rebuilds on unrelated changes and is [not supported by `nix-update`](https://github.com/Mic92/nix-update/issues/335).

```bash
# Update vendor hash after dependabot bumps go.mod or Cargo.toml
nix-update --flake pname --version=skip
```

## Design Notes

- Why `nixpkgs-vet` is not enforced: Local packages share root `go.mod`, `internal/`, and `config/` via relative paths (`../../../../.`), which `nixpkgs-vet` forbids (`NPV-123`).
- Why not [NUR](https://github.com/nix-community/NUR): NUR only checks evaluation without building or hosting binary caches, and expects slim repositories rather than a monorepo with full NixOS and Home Manager CI.
