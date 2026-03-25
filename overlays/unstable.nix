nixpkgs-unstable: final: _prev: {
  # Apply nixpkgs commits or PRs as urgent patches. It is especially helpful when a commit has not even reached the unstable channels.
  unstable =
    let
      # Use `final` because `applyPatches` and `fetchpatch2` are derived from the base (stable) nixpkgs.
      patched = final.applyPatches {
        name = "patched-nixpkgs-unstable";
        src = nixpkgs-unstable;
        patches = [
          # Using dprint 0.52.1 does not run on official GHA. See https://github.com/dprint/dprint/issues/1113#issuecomment-4110214566 for detail
          (final.fetchpatch2 {
            name = "dprint-0.53.0.patch";
            url = "https://patch-diff.githubusercontent.com/raw/nixos/nixpkgs/pull/502638.patch?full_index=1";
            hash = "sha256-icunLMLCg17gQZHWwbMpHnkg94ZkOJkWW6pmZCHCC7A=";
          })
        ];
      };
    in
    import patched {
      inherit (final) config;
      inherit (final.stdenvNoCC.hostPlatform) system;
    };
}
