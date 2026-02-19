{ prev, fetchpatch, ... }:
# Patched and override existing name because of it is not configurable
# https://github.com/NixOS/nixpkgs/blob/nixos-25.11/pkgs/by-name/mo/mozc/package.nix
# The mozc package in nixpkgs often remains on old versions, primarily due to bazel dependency issues.
# However, the latest mozc(2.31.5712.102 or later) includes a crucial patch to fix the Super key hijacking.
prev.mozc.overrideAttrs (
  _finalAttrs: _previousAttrs: {
    patches = [
      (fetchpatch {
        name = "GH-1277.patch";
        url = "https://patch-diff.githubusercontent.com/raw/google/mozc/pull/1059.patch?full_index=1";
        hash = "sha256-c67WPdvPDMxcduKOlD2z0M33HLVq8uO8jzJVQfBoxSY=";
      })
    ];
  }
)
