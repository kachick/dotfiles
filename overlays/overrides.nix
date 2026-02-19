{ home-manager-linux, home-manager-darwin }:
final: prev: {
  # Patched and override existing name because of it is not configurable
  # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/pkgs/by-name/mo/mozc/package.nix
  # The mozc package in nixpkgs often remains on old versions, primarily due to bazel dependency issues.
  # However, the latest mozc(2.31.5712.102 or later) includes a crucial patch to fix the Super key hijacking.
  mozc = prev.mozc.overrideAttrs (
    finalAttrs: previousAttrs: {
      patches = [
        (prev.fetchpatch {
          name = "GH-1277.patch";
          url = "https://patch-diff.githubusercontent.com/raw/google/mozc/pull/1059.patch?full_index=1";
          hash = "sha256-c67WPdvPDMxcduKOlD2z0M33HLVq8uO8jzJVQfBoxSY=";
        })
      ];
    }
  );

  # Workaround for https://github.com/NixOS/nixpkgs/issues/488689
  # The fix https://github.com/NixOS/nixpkgs/pull/482476 was merged into staging, but master still lacks the patch.
  # This uses the previous version from unstable on Darwin to prevent CI failures.
  # Essentially, this override is a dirty and fool approach for security fixes.
  # But it is okay here because Darwin uses inetutils only for Home Manager.
  # It is not global on Darwin.
  inetutils = if prev.stdenv.hostPlatform.isDarwin then prev.unstable.inetutils else prev.inetutils;

  home-manager =
    (if prev.stdenv.hostPlatform.isDarwin then home-manager-darwin else home-manager-linux)
    .packages.${prev.stdenv.hostPlatform.system}.home-manager.override
      {
        inetutils = final.inetutils;
      };
}
