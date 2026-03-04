{ kanata-tray }:
final: _prev:
let
  system = final.stdenvNoCC.hostPlatform.system;
in
{
  # Pinned or external packages that we want to build and cache in CI.
  #
  # Why do I need special handling for zed-editor?:
  #   See GH-1085, GH-1134 and GH-1402
  #   zed-editor package was very flaky in hydra between both stable and unstable channels.
  #   The authors send and package maintainers merge updating PRs immediately without attempting build on any platforms.
  #   Since I can't trust stable channel, unstable channel is a bit better to fix it faster.
  #
  # Limitation: Don't add unfree packages such as cloudflare-warp, vscode
  pinned = {
    # Pinning kanata-tray from the flake input
    # It seems kanata-tray flake provides 'kanata-tray' and 'default' (which is kanata-tray)
    kanata-tray = kanata-tray.packages.${system}.default;

    # Pinned from nixpkgs-unstable
    inherit (_prev.unstable) zed-editor;

    # Expose the patched mozc for CI building
    inherit (final) mozc;
  };
}
