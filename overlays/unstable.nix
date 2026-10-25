nixpkgs-unstable: final: _prev: {
  # Apply nixpkgs commits or PRs as urgent patches. It is especially helpful when a commit has not even reached the unstable channels.
  # Use `final` because `applyPatches` and `fetchpatch2` are derived from the base (stable) nixpkgs.
  unstable = import nixpkgs-unstable {
    inherit (final) config;
    inherit (final.stdenvNoCC.hostPlatform) system;
  };

  inherit (final.unstable) installFonts;

  /*
    unstable =
      let
        patched = final.applyPatches {
          name = "patched-nixpkgs-unstable";
          src = nixpkgs-unstable;
          patches = [
            (final.fetchpatch2 {
              name = "what.patch";
              url = "<url_here>.patch?full_index=1";
              hash = "";
            })
          ];
        };
      in
      import patched {
        inherit (final) config;
        inherit (final.stdenvNoCC.hostPlatform) system;
      };
  */
}
