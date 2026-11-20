{
  kanata-tray,
  ghadiag,
  iets,
  home-manager,
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

    iets = iets.packages.${system}.default;

    inherit (_prev)
      # See GH-1085, GH-1134, and GH-1402
      # The zed-editor package has been very flaky in Hydra: https://discourse.nixos.org/t/why-is-zed-editor-not-cached/60452/4
      # Build and cache it in CI to ensure fast availability.
      zed-editor
      ;

    # Expose overridden packages for dedicated CI builds and binary caching
    inherit (final)
      ibus
      nix-update
      ;

    # Pinning home-manager from the flake input
    home-manager = home-manager.packages.${system}.home-manager;
  };
}
