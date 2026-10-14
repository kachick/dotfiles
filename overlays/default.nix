{
  nixpkgs-unstable,
  kanata-tray,
  home-manager-linux,
  selfup,
}:
[
  (import ./local.nix)
  (import ./unstable.nix nixpkgs-unstable)
  (import ./pinned.nix {
    inherit
      kanata-tray
      home-manager-linux
      selfup
      ;
  })
  (import ./overrides { })
]
