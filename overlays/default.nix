{
  nixpkgs-unstable,
  kanata-tray,
  home-manager-linux,
  home-manager-darwin,
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
    unstable = import nixpkgs-unstable {
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
          version = "0.28.2";

          src = prev.fetchurl {
            url = "https://github.com/google-gemini/gemini-cli/releases/download/v${finalAttrs.version}/gemini.js";
            hash = "sha256-QrYpxMVm0LW42bL6yQn2TuBdyII4hVO2zlesMPiI0DQ=";
          };

          schema = prev.fetchurl {
            url = "https://raw.githubusercontent.com/google-gemini/gemini-cli/v${finalAttrs.version}/schemas/settings.schema.json";
            hash = "sha256-BUH+DmCw9pwY+6QRoP+oFuAuxUaVFNTiFGBgvGt4Nzo=";
          };

          # Added JSON schema in package:
          # https://github.com/google-gemini/gemini-cli/issues/5302
          #
          # I removed the patches to disable autoUpdater. They are better for Nixpkgs, but simple packaging is okay for my use.
          # Instead of using patches, set up the config yourself:
          # https://github.com/google-gemini/gemini-cli/blob/main/docs/get-started/configuration.md
          #
          # Keeping ripgrep patches here. Update them once this issue is resolved:
          # https://github.com/google-gemini/gemini-cli/issues/11438
          installPhase = ''
            runHook preInstall

            install -D "$src" "$out/bin/gemini"
            install -D "$schema" "$out/share/settings.schema.json"

            substituteInPlace "$out/bin/gemini" \
              --replace-fail 'const existingPath = await resolveExistingRgPath();' 'const existingPath = "${prev.unstable.lib.getExe prev.unstable.ripgrep}";'

            runHook postInstall
          '';
        }
      );

      rclone = prev.unstable.rclone.overrideAttrs (
        finalAttrs: previousAttrs: {
          version = "1.73.0";

          # Since 1.73.0, official rclone merged filen-rclone
          # It is frequently updated rather than FilenCloudDienste/filen-rclone
          # However it is not yet reached in nixos-unstable: https://nixpkgs-tracker.ocfox.me/?pr=485515
          src = prev.fetchFromGitHub {
            owner = "rclone";
            repo = "rclone";
            tag = "v${finalAttrs.version}";
            hash = "sha256-g/ofD/KsUOXVTOveHKddPN9PP5bx7HWFPct1IhJDZYE=";
          };

          patches = [
            # Pre-release patch for Filen.io: https://github.com/rclone/rclone/pull/9145
            (prev.fetchpatch2 {
              name = "fix-32-bit-targets-not-being-able-to-list-directories";
              url = "https://github.com/rclone/rclone/commit/ed5bd327c08bb222e1ab3888bb0869c76e3be629.patch?full_index=1";
              hash = "sha256-PzfjnGRG0Gpuggb62H6/W4H4HH0DlZ2XE9f7wLuuJgE=";
            })

            # Pre-release patch for Filen.io: https://github.com/rclone/rclone/pull/9140
            (prev.fetchpatch2 {
              name = "fix-potential-panic-in-case-of-error-during-upload.patch";
              url = "https://github.com/rclone/rclone/commit/88b484722a3fb7ff2a7bf7af16d00647b27fd421.patch?full_index=1";
              hash = "sha256-DYmYPlqm5IhHDjWLaBNRW6nafPk8sJSp5taLa1P/7m8=";
            })
          ];

          vendorHash = "sha256-7x+3/0u4a0S8wN17u1YFECF2/ATDYh4Byu11RUXz8VM=";

          # nixpkgs definition is still using rec, so I should override at here until using finalAttrs
          # https://github.com/NixOS/nixpkgs/blob/ac7c30e2ca1f70e82222e1d95a0221c1edee9228/pkgs/by-name/rc/rclone/package.nix#L18
          ldflags = [
            "-s"
            "-w"
            "-X github.com/rclone/rclone/fs.Version=${finalAttrs.version}"
          ];
        }
      );
    };
  })
]
