{ kanata-tray }:
final: _prev:
let
  system = final.stdenvNoCC.hostPlatform.system;
in
{
  pinned = {
    # Pinning kanata-tray from the flake input
    # It seems kanata-tray flake provides 'kanata-tray' and 'default' (which is kanata-tray)
    kanata-tray = kanata-tray.packages.${system}.default;

    # Pinned from nixpkgs-unstable
    inherit (final.unstable) zed-editor;
  };
}
