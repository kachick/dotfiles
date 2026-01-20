{
  edge-nixpkgs,
  kanata-tray,
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
      inherit (final) config;
      inherit (final.stdenvNoCC.hostPlatform) system;
    };
  })

  # Patched and override existing name because of it is not configurable
  (final: prev: {
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
  })

  (final: prev: {
    # Patched packages should be put here if exist
    # Keep patched attr even if empty. To expose and runnable `nix build .#pname` for patched namespace
    patched = {
      # "patched" might be inaccurate wording for this package. However this place is the better for my use. And not a lie. The channel might be different with upstream
      inherit (kanata-tray.packages.${final.stdenvNoCC.hostPlatform.system}) kanata-tray;

      # pname = prev.unstable.pname.overrideAttrs (
      #   finalAttrs: previousAttrs: {
      #   }
      # );

      # Overriding non mkDerivation often makes hard to modify the hash(not src hash). See following workaround
      # rust:
      #   - https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/20
      #   - https://discourse.nixos.org/t/nixpkgs-overlay-for-mpd-discord-rpc-is-no-longer-working/59982/2
      # npm: https://discourse.nixos.org/t/npmdepshash-override-what-am-i-missing-please/50967/4

      # - Should locally override to use latest stable for now: https://github.com/NixOS/nixpkgs/pull/444028#issuecomment-3310117634
      # - OSS. Apache-2.0
      # - Reasonable choice rather than gemini-cli package. gemini-cli-bin is easier to track latest for now
      gemini-cli-bin = prev.unstable.gemini-cli-bin.overrideAttrs (
        finalAttrs: previousAttrs: {
          # Don't trust `gemini --version` results, for example, 0.6.1 actually returned `0.6.0`.
          version = "0.24.4";

          src = prev.fetchurl {
            url = "https://github.com/google-gemini/gemini-cli/releases/download/v${finalAttrs.version}/gemini.js";
            hash = "sha256-xteIV43P5qPOamxsGjCXeCkd1zQmNNbMhvzSWc26DQU=";
          };
        }
      );
    };
  })
]
