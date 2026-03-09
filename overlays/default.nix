{
  nixpkgs-unstable,
  kanata-tray,
}:
[
  (import ./local.nix)
  (import ./unstable.nix nixpkgs-unstable)
  (import ./pinned.nix { inherit kanata-tray; })
  (import ./overrides { })
]
