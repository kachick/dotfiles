# Design Note: Issue #1490 - Improving CI Binary Caching and Unfree Handling

## Goal
Enable binary caching for NixOS and Home Manager configurations without leaking unfree packages to public Cachix.

## Findings from Research (2026-03-11)
- We can identify unfree packages from actual configurations using `config.nixpkgs.allowedUnfreePackageNames`.
- Simple string matching (grep) for filtering is fragile and causes false positives (e.g., `vscode` matches `vscode-langservers-extracted`).
- Module-provided unfree packages (like `cloudflare-warp`) are correctly included in `system.build.toplevel` closure and can be detected.

## Proposed Strategy (Nix-native filtering)
Instead of regex-based filtering in CI, we will use Nix evaluation to generate the list of safe paths.

### Idea: Use `system.path.paths`
NixOS's `config.system.path` is a derivation that symlinks all system-wide packages. By filtering its inputs directly in Nix, we get a reliable list of "Safe Packages" without any string parsing.

### Verified on `algae`
The `environment.systemPackages` and module-provided packages are accessible at evaluation time.

## Draft Workflow
1. Build the system with `allowUnfree = true`.
2. Evaluate a "Safe Closure" which is the system closure minus unfree derivations.
3. Push only the Safe Closure to Cachix.

---
Assisted-by: Gemini CLI <gemini-cli@google.com>
