nixpkgs-unstable: final: _prev: {
  # Apply nixpkgs commits or PRs as urgent patches. It is especially helpful when a commit has not even reached the unstable channels.
  unstable =
    let
      # Use `final` because `applyPatches` and `fetchpatch2` are derived from the base (stable) nixpkgs.
      patched = final.applyPatches {
        name = "patched-nixpkgs-unstable";
        src = nixpkgs-unstable;
        patches = [
          # https://github.com/kachick/dotfiles/pull/1518#issuecomment-4123441635
          # https://github.com/NixOS/nixpkgs/issues/503112
          # https://github.com/kachick/nixpkgs/pull/6
          (final.fetchpatch2 {
            name = "winboat-pin-deps.patch";
            url = "https://patch-diff.githubusercontent.com/raw/kachick/nixpkgs/pull/6.patch?full_index=1";
            hash = "sha256-yJpcO1ZeK65HlJl+mv6b3U/aHGIyEyKCLFOGURbU9vA=";
          })
        ];
      };
    in
    import patched {
      inherit (final) config;
      inherit (final.stdenvNoCC.hostPlatform) system;
    };
}
