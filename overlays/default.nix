{
  kanata-tray,
  ghadiag,
  cntr,
  iets,
  home-manager,
}:
[
  (import ./local.nix)
  (import ./pinned.nix {
    inherit
      kanata-tray
      ghadiag
      cntr
      iets
      home-manager
      ;
  })
  (import ./overrides { })
]
