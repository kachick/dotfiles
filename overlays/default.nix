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
    # TODO: Use `services.gnome.gcr-ssh-agent.enable = false` since nixos-25.11
    #
    # https://github.com/NixOS/nixpkgs/blob/nixos-25.05/pkgs/by-name/gn/gnome-keyring/package.nix
    # Backport https://github.com/NixOS/nixpkgs/pull/379731 to disable SSH_AUTH_SOCK by gnome-keyring. This is required because of I should avoid GH-714 but realize GH-1015
    #
    # And it should be override the package it self, the module is not configurable for the package. https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/desktops/gnome/gnome-keyring.nix
    gnome-keyring = prev.unstable.gnome-keyring;
  })

  # Pacthed packages
  (final: prev: {
    patched = {
      # Use latest lima, it makes faster build especially patching: https://github.com/NixOS/nixpkgs/pull/415093
      lima = prev.unstable.lima.overrideAttrs (
        finalAttrs: previousAttrs: {
          # This patch is needed on Linux. However enables on macOS too for testing.
          patches = [
            (prev.fetchpatch {
              # https://github.com/lima-vm/lima/pull/3637
              name = "lima-suppress-gssapi-warning.patch";
              url = "https://github.com/lima-vm/lima/pull/3637.patch?full_index=1";
              hash = "sha256-Q352EyM6vY/uhvm6s31Ff/IzHWd87EJm6WkFN9HFTJg=";
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

      # - Need https://github.com/NixOS/nixpkgs/pull/419521 for updating and cleanups
      # - I just need MoreWaita for mimetype icons, and I should remove them at here to respect app original icons.
      #   See https://specifications.freedesktop.org/icon-theme-spec/latest/#icon_lookup for detail
      #
      # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/mo/morewaita-icon-theme/package.nix
      morewaita-icon-theme = prev.unstable.morewaita-icon-theme.overrideAttrs (
        finalAttrs: previousAttrs: {
          preInstall = ''
            rm -rf ./scalable/apps ./symbolic/apps
            find . -xtype l -delete
          '';
        }
      );
    };
  })
]
