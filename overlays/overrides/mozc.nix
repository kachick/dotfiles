{ prev, fetchpatch, ... }:
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
