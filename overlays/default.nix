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
        # configureFlags -> mesonFlags: https://github.com/NixOS/nixpkgs/commit/58d1ecc5c3621b56577a9c8f955672ac935c1eba
        mesonFlags = final.lib.lists.remove "-Dssh-agent=true" previousAttrs.mesonFlags;
      }
    );
  })

  # Pacthed packages
  (final: prev: {
    patched = {
      # Based on forked version of lima, because of the extracting addiitional guest agents made much faster to build.
      # Mandatory if no binary cache such as this patch
      # (It will make slower building on macOS, because they don't need this ssh patch. However testing with latest is better for now.)
      # ref: https://github.com/NixOS/nixpkgs/pull/415093
      lima = prev.my.lima.overrideAttrs (
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

      # nixpkgs' definition roughly includes all upstream files, it is unnecessary for actual use
      # core difference is removing the apps directory, I just need MoreWaita for mimetype icons
      # some apps icons are also used as directory icon, however I can ignore them for now, seems I'm not using them
      morewaita-icon-theme = prev.unstable.morewaita-icon-theme.overrideAttrs (
        finalAttrs: previousAttrs: {
          preInstall = ''
            rm -rf ./scalable/apps ./symbolic/apps ./.github ./_dev
            rm ./*.md ./*.sh ./*.build
            find . -xtype l -delete
          '';
        }
      );
    };
  })
]
