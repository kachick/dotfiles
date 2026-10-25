nixpkgs-unstable: final: _prev: {
  # Apply nixpkgs commits or PRs as urgent patches. It is especially helpful when a commit has not even reached the unstable channels.
  # Use `final` because `applyPatches` and `fetchpatch2` are derived from the base (stable) nixpkgs.
  unstable =
    let
      patched = final.applyPatches {
        name = "patched-nixpkgs-unstable";
        src = nixpkgs-unstable;
        patches = [
          (final.fetchpatch2 {
            name = "cloudflare-warp-2026.8.2115.0.patch";
            url = "https://github.com/NixOS/nixpkgs/commit/d0fdd02155a254227dce86380a58a4bf94f1e56f.patch?full_index=1";
            hash = "sha256-XhWraH6MwM9fn/OaqU4mVAxD3qWl/K7VBzGg9wRQI9c=";
          })
        ];
      };
    in
    import patched {
      inherit (final) config;
      inherit (final.stdenvNoCC.hostPlatform) system;
    };

  inherit (final.unstable) installFonts;
}
