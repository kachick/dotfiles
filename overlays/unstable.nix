nixpkgs-unstable: final: _prev: {
  # Apply nixpkgs commits or PRs as urgent patches. It is especially helpful when a commit has not even reached the unstable channels.
  unstable =
    let
      # Use `final` because `applyPatches` and `fetchpatch2` are derived from the base (stable) nixpkgs.
      patched = final.applyPatches {
        name = "patched-nixpkgs-unstable";
        src = nixpkgs-unstable;
        patches = [
          (final.fetchpatch2 {
            name = "electron_39-fix-patch_dir.patch";
            url = "https://github.com/NixOS/nixpkgs/commit/a499dfba7b52aac86504356512836550e9d49a5a.patch?full_index=1";
            hash = "sha256-vRb0uf927IR5knjFkH6Jsm24ZPFnhq58l4DAV0HMieM=";
          })
        ];
      };
    in
    import patched {
      inherit (final) config;
      inherit (final.stdenvNoCC.hostPlatform) system;
    };
}
