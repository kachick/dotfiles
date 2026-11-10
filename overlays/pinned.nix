{
  kanata-tray,
  ghadiag,
  cntr,
  iets,
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

    iets = iets.packages.${system}.default;

    # Pinning cntr from the flake input
    # Upstream nixpkgs PR https://github.com/NixOS/nixpkgs/pull/548453 is stuck due to test failures.
    # Integration tests require writing to /proc/self/setgroups and unsharing user namespaces,
    # which fails in sandboxed builds (e.g. GitHub Actions runners), so disable checks.
    #
    # Patches:
    # - cntr-fork-into-pidns.patch: setns(CLONE_NEWPID) does not change the caller's PID namespace,
    #   causing setpgid EPERM in interactive bash. Fork before execve to enter the container PID namespace.
    # Call package directly from source to avoid deprecated stdenv.isDarwin evaluation warning in upstream flake.nix
    cntr =
      (final.callPackage "${cntr}/default.nix" {
        self = cntr;
      }).overrideAttrs
        (old: {
          patches = (old.patches or [ ]) ++ [
            ./patches/cntr-fork-into-pidns.patch
          ];
          doCheck = false;
        });

    inherit (_prev)
      # See GH-1085, GH-1134, and GH-1402
      # The zed-editor package has been very flaky in Hydra: https://discourse.nixos.org/t/why-is-zed-editor-not-cached/60452/4
      # Build and cache it in CI to ensure fast availability.
      zed-editor
      ;

    # Expose the patched nix-update for CI building and workflows
    inherit (final) nix-update;

    # Pinning home-manager from the flake input
    home-manager = home-manager-linux.packages.${system}.home-manager;
  };
}
