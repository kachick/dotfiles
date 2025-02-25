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

  # Keep minimum patches as possible. Because of they can not use official binary cache. See GH-754

  # Patched and override existing name because of it is not cofigurable
  (final: prev: {
    # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/by-name/gn/gnome-keyring/package.nix
    # To disable SSH_AUTH_SOCK by gnome-keyring. This is required because of I should avoid GH-714 but realize GH-1015
    #
    # And it should be override the package it self, the module is not configurable for the package. https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/desktops/gnome/gnome-keyring.nix
    gnome-keyring = prev.gnome-keyring.overrideAttrs (
      finalAttrs: previousAttrs: {
        # https://github.com/NixOS/nixpkgs/issues/140824#issuecomment-2573660493
        configureFlags = final.lib.lists.remove "--enable-ssh-agent" previousAttrs.configureFlags;
      }
    );
  })

  # Pacthed packages
  (final: prev: {
    patched = {
      # TODO: Update with https://github.com/NixOS/nixpkgs/pull/385014 progress
      cloudflare-warp = prev.unstable.cloudflare-warp.overrideAttrs (
        finalAttrs: previousAttrs: {
          version = "2025.1.861";
          src = final.fetchurl {
            url = "https://pkg.cloudflareclient.com/pool/noble/main/c/cloudflare-warp/cloudflare-warp_${finalAttrs.version}.0_amd64.deb";
            hash = "sha256-9Y1mBKS74x1F3OEusqvm7W8RoJnfBHnXTtwbFVfhjc4=";
          };
        }
      );

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
