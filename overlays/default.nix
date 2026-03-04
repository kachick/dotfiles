{
  nixpkgs-unstable,
  kanata-tray,
  zed-editor,
  home-manager-linux,
  home-manager-darwin,
}:
[
  (import ./my.nix)
  (import ./unstable.nix nixpkgs-unstable)
  (import ./overrides { inherit home-manager-linux home-manager-darwin; })
  (import ./patched { inherit kanata-tray zed-editor; })
]
