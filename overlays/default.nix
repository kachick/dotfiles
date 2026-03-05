{
  self,
  nixpkgs-unstable,
  kanata-tray,
  home-manager-linux,
  home-manager-darwin,
}:
[
  (import ./local.nix { inherit self; })
  (import ./unstable.nix nixpkgs-unstable)
  (import ./pinned.nix { inherit kanata-tray; })
  (import ./overrides { inherit home-manager-linux home-manager-darwin; })
]
