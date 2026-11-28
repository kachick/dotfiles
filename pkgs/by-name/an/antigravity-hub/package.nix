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
  version = "2.36.0";
  buildId = "5596661662220288";
  wholeVersion = "${version}-${buildId}";

  throwSystem = throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}";

  sourceData = {
    x86_64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/${wholeVersion}/linux-x64/Antigravity.tar.gz";
      hash = "sha256-b+QY8I52DAt/KXXfna7262y8R8ZRYSUTSeDOJVxgj7Y=";
    };
    aarch64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/${wholeVersion}/linux-arm/Antigravity.tar.gz";
      hash = "sha256-LDIvCnfb0Fkc2qoosb5MpJ5WsTe7NBD0PpxRDlYA2D8=";
    };
    aarch64-darwin = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/${wholeVersion}/darwin-arm/Antigravity.zip";
      hash = "sha256-MnDH2gYZ1HpgVz39eMt+kN3Bby50DxjfmAu+k1l7O80=";
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
