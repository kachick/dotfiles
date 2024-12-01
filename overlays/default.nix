{
  edge-nixpkgs,
  ...
}:
[
  (final: _prev: {
    my = import ../pkgs {
      pkgs = final.pkgs;
    };
  })

  (final: _prev: {
    unstable = import edge-nixpkgs {
      system = final.system;
    };
  })

  # Pacthed packages

  (final: prev: {
    lima = prev.lima.overrideAttrs (
      finalAttrs: previousAttrs:
      if prev.stdenv.hostPlatform.isLinux then
        {
          patches = [
            (prev.fetchpatch {
              # https://github.com/lima-vm/lima/pull/2943
              name = "lima-fix-systemd-target.patch";
              url = "https://github.com/lima-vm/lima/commit/ca778e338ab95524555ba4d23bd6398be5a6ee0f.patch";
              hash = "sha256-bCHZv1qctr39PTRJ60SPnXLArXGl4/FV45G+5nDxMFY=";
            })

            (prev.fetchpatch {
              # https://github.com/kachick/lima/pull/1
              name = "lima-suppress-gssapi-warning.patch";
              url = "https://patch-diff.githubusercontent.com/raw/kachick/lima/pull/1.patch";
              hash = "sha256-QTEYorN+nj66WMlMz+hsoZUWPnlGPDCw0VSsqsiayls=";
            })
          ];
        }
      else
        { }
    );
  })
]
