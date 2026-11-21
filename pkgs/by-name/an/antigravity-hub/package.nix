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
  version = "2.34.0";
  buildId = "5887025308631040";
  wholeVersion = "${version}-${buildId}";

  throwSystem = throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}";

  sourceData = {
    x86_64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/${wholeVersion}/linux-x64/Antigravity.tar.gz";
      hash = "sha256-R4xo+Gye9hpQIYWjnpzuxmsSdqalOxkaGbDZzoaYNts=";
    };
    aarch64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/${wholeVersion}/linux-arm/Antigravity.tar.gz";
      hash = "sha256-kfMc5Qx5XgVx55IlERGf8+evwu5PZAqX1p260gY8GGY=";
    };
    aarch64-darwin = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/${wholeVersion}/darwin-arm/Antigravity.zip";
      hash = "sha256-u1ZNuVt5dh5mpYYF3fTWcCDt6IZfkCuLdBL4e9OEzJE=";
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
