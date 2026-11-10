{
  kanata-tray,
  ghadiag,
  cntr,
  home-manager-linux,
}:
[
  (import ./local.nix)
  (import ./pinned.nix {
    inherit
      kanata-tray
      ghadiag
      cntr
      home-manager-linux
      ;
  })
  (import ./overrides { })
]
