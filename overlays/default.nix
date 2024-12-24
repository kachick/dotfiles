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
      system = final.system;
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

      # Require unstable to apply https://github.com/NixOS/nixpkgs/pull/355534
      kind = prev.unstable.kind.overrideAttrs (
        finalAttrs: previousAttrs: {
          patches = previousAttrs.patches ++ [
            (prev.fetchpatch2 {
              # https://github.com/kubernetes-sigs/kind/pull/3814
              url = "https://patch-diff.githubusercontent.com/raw/kubernetes-sigs/kind/pull/3814.patch";
              hash = "sha256-zoS+C16lURnxSgnbxwIfBoJOWPIamOtmS3HKxGuWkYI=";
            })
          ];
        }
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

      # TODO: Write script and put into nixpkgs, updating this is an annoy task :<
      # References
      # https://github.com/NixOS/nixpkgs/pull/358952
      # https://github.com/cloudflare/cloudflare-docs/pull/18927/files#diff-8fefe770ff52ff199e5f0716f65605428839371afac5d0007c5cc9da64d29278R28-R42
      cloudflare-warp = prev.cloudflare-warp.overrideAttrs (
        finalAttrs: previousAttrs: rec {
          version = "2024.12.554";
          suffix =
            {
              aarch64-linux = "arm64";
              x86_64-linux = "amd64";
            }
            .${final.stdenv.hostPlatform.system}
              or (throw "Unsupported system: ${final.stdenv.hostPlatform.system}");
          src = final.fetchurl {
            url = "https://pkg.cloudflareclient.com/pool/noble/main/c/cloudflare-warp/cloudflare-warp_${version}.0_${suffix}.deb";
            hash =
              {
                aarch64-linux = "sha256-FdT7C5ltqCXdVToIFdEgMKVpvCf6PVcvTpvMTCJj5vc=";
                x86_64-linux = "sha256-8FMDVUoAYInXVJ5mwpPpUxECAN8safiHetM03GJTmTg=";
              }
              .${final.stdenv.hostPlatform.system}
                or (throw "Unsupported system: ${final.stdenv.hostPlatform.system}");
          };
        }
      );
    };
  })
]
