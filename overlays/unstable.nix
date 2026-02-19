nixpkgs-unstable: final: _prev: {
  unstable = import nixpkgs-unstable {
    inherit (final) config;
    inherit (final.stdenvNoCC.hostPlatform) system;
  };
}
