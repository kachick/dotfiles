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
          # https://hydra.nixos.org/build/325252976
          # https://nixpkgs-tracker.ocfox.me/?pr=503185
          (final.fetchpatch2 {
            name = "winboat-pin-deps.patch";
            url = "https://github.com/NixOS/nixpkgs/commit/92c21151c05ebf78230780f2df7e8c303f170e0a.patch?full_index=1";
            hash = "sha256-v6wwrRtTGXG7WXgxym3hd6RbVhxGTL5NRB54hb4ezGQ=";
          })
        ];
      };
    in
    import patched {
      inherit (final) config;
      inherit (final.stdenvNoCC.hostPlatform) system;
    };
}
