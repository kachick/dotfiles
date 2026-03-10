{
  nixpkgs-unstable,
  kanata-tray,
  home-manager-linux,
  home-manager-darwin,
}:
[
  (import ./local.nix)
  (import ./unstable.nix nixpkgs-unstable)
  (import ./pinned.nix {
    inherit
      kanata-tray
      home-manager-linux
      home-manager-darwin
      ;
  })
  (import ./overrides { })
]
