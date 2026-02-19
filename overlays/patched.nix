{ kanata-tray }:
final: prev: {
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
        version = "0.29.2";

        src = prev.fetchurl {
          url = "https://github.com/google-gemini/gemini-cli/releases/download/v${finalAttrs.version}/gemini.js";
          hash = "sha256-eE/UBPx3V9aSwaGoWpanSTqOT7uu1ZxAhORA6D9ah40=";
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
        # Remove these patches once 1.73.1 is available
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
}
