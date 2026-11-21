{
  kanata-tray,
  ghadiag,
  iets,
  home-manager,
}:
[
  (import ./local.nix)
  (import ./pinned.nix {
    inherit
      kanata-tray
      ghadiag
      iets
      home-manager
      ;
  })
  (import ./overrides { })
]
