{
  kanata-tray,
  ghadiag,
  cntr,
  home-manager-linux,
}:
final: _prev:
let
  system = final.stdenvNoCC.hostPlatform.system;
in
{
  # Pinned or external packages that we want to build and cache in CI.
  #
  # Limitation: Don't add unfree packages such as cloudflare-warp, vscode
  pinned = {
    # Pinning kanata-tray from the flake input
    # It seems kanata-tray flake provides 'kanata-tray' and 'default' (which is kanata-tray)
    kanata-tray = kanata-tray.packages.${system}.default;

    ghadiag = ghadiag.packages.${system}.default;

    # Pinning cntr from the flake input
    # Upstream nixpkgs PR https://github.com/NixOS/nixpkgs/pull/548453 is stuck due to test failures,
    # so we build directly from the upstream release tag.
    cntr = cntr.packages.${system}.default;

    inherit (_prev.unstable)
      # See GH-1085, GH-1134, and GH-1402
      # The zed-editor package has been very flaky in Hydra: https://discourse.nixos.org/t/why-is-zed-editor-not-cached/60452/4
      # Since I can't trust stable channels, I use the unstable channel to resolve package-level issues faster,
      # and I build and cache it myself.
      zed-editor
      ;

    # Expose the patched nix-update for CI building and workflows
    inherit (final) nix-update;

    # Pinning home-manager from the flake input
    home-manager = home-manager-linux.packages.${system}.home-manager;
  };
}
