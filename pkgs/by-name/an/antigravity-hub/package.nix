{
  stdenvNoCC,
  fetchurl,
  antigravity-hub,
  writeShellApplication,
  curl,
  jq,
  gnused,
  nix,
  yq-go,
}:

let
  version = "2.35.1";
  buildId = "4615540875067392";
  wholeVersion = "${version}-${buildId}";

  throwSystem = throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}";

  sourceData = {
    x86_64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/${wholeVersion}/linux-x64/Antigravity.tar.gz";
      hash = "sha256-2SEDmob7+g0GloyXPq3/qDVytDSjUadxuK2fJBpJPX4=";
    };
    aarch64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/${wholeVersion}/linux-arm/Antigravity.tar.gz";
      hash = "sha256-w2qY5t/gbtlYnflcviagAmQTECGrd5x6DzBcgIy6iXM=";
    };
    aarch64-darwin = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/${wholeVersion}/darwin-arm/Antigravity.zip";
      hash = "sha256-N/eAQkJ7Z70Ue4rMv3gKndxjui4RYlP8TeVW8+xhHYw=";
    };
  };
in
antigravity-hub.overrideAttrs (old: {
  inherit version;

  src = sourceData.${stdenvNoCC.hostPlatform.system} or throwSystem;

  passthru = (old.passthru or { }) // {
    inherit buildId wholeVersion;
    updateScript = writeShellApplication {
      name = "antigravity-hub-updater";

      runtimeInputs = [
        curl
        jq
        gnused
        nix
        yq-go
      ];

      text = builtins.readFile ./update.bash;
    };
  };

  meta = (old.meta or { }) // {
    changelog = "https://antigravity.google/docs/changelog?tab=app";
  };
})
