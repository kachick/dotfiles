{
  nixpkgs-unstable,
  kanata-tray,
  home-manager-linux,
  home-manager-darwin,
}:
[
  (import ./my.nix)
  (import ./unstable.nix nixpkgs-unstable)
  (import ./overrides.nix { inherit home-manager-linux home-manager-darwin; })
  (import ./patched.nix { inherit kanata-tray; })
]
