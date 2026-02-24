{ unstable, fetchurl, ... }:
# - Should locally override to use latest stable for now: https://github.com/NixOS/nixpkgs/pull/444028#issuecomment-3310117634
# - OSS. Apache-2.0
# - Reasonable choice rather than gemini-cli package. gemini-cli-bin is easier to track latest for now
unstable.gemini-cli-bin.overrideAttrs (
  finalAttrs: _previousAttrs: {
    # Don't trust `gemini --version` results, for example, 0.6.1 actually returned `0.6.0`.
    version = "0.29.6";

    src = fetchurl {
      url = "https://github.com/google-gemini/gemini-cli/releases/download/v${finalAttrs.version}/gemini.js";
      hash = "sha256-RrosV+geuGqnsxqy6EqEZJcgM3u8FvukRq5C98LiNYY=";
    };

    schema = fetchurl {
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
        --replace-fail 'const existingPath = await resolveExistingRgPath();' 'const existingPath = "${unstable.lib.getExe unstable.ripgrep}";'

      runHook postInstall
    '';
  }
)
