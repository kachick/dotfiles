{
  edge-nixpkgs,
  ...
}:
[
  (final: _prev: {
    my = final.lib.packagesFromDirectoryRecursive {
      inherit (final) callPackage;
      directory = ../pkgs;
    };
  })

  (final: _prev: {
    unstable = import edge-nixpkgs {
      inherit (final) system config;
    };
  })

  # Pacthed packages

  (final: prev: {
    patched = {
      # TODO: Replace to stable since nixos-25.05, stable 24.11 does not include https://github.com/NixOS/nixpkgs/pull/361378
      lima = prev.unstable.lima.overrideAttrs (
        finalAttrs: previousAttrs:
        if prev.stdenv.hostPlatform.isLinux then
          {
            patches = [
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

      # TODO: Remove after merging https://github.com/NixOS/nixpkgs/pull/301440
      cozette = prev.cozette.overrideAttrs (
        finalAttrs: previousAttrs: {
          installPhase = ''
            runHook preInstall

            install -Dm644 *.ttf -t $out/share/fonts/truetype
            install -Dm644 *.otf -t $out/share/fonts/opentype
            install -Dm644 *.bdf -t $out/share/fonts/misc
            install -Dm644 *.otb -t $out/share/fonts/misc
            install -Dm644 *.woff -t $out/share/fonts/woff
            install -Dm644 *.woff2 -t $out/share/fonts/woff2
            install -Dm644 *.psf -t $out/share/consolefonts

            runHook postInstall
          '';
        }
      );
    };
  })
]
