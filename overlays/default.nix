{
  nixpkgs-unstable,
  kanata-tray,
  home-manager-linux,
  home-manager-darwin,
}:
[
  (import ./local.nix { inherit home-manager-linux home-manager-darwin; })
  (import ./unstable.nix nixpkgs-unstable)
  (import ./pinned.nix { inherit kanata-tray; })
  (import ./overrides { })
]
