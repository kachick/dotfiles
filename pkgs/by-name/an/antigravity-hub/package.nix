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
  version = "2.35.2";
  buildId = "4585983447007232";
  wholeVersion = "${version}-${buildId}";

  throwSystem = throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}";

  sourceData = {
    x86_64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/${wholeVersion}/linux-x64/Antigravity.tar.gz";
      hash = "sha256-LTPbKCsemzx1gsFA2rnoaEjxs3oFv6Sh3/f0TeG/ME8=";
    };
    aarch64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/${wholeVersion}/linux-arm/Antigravity.tar.gz";
      hash = "sha256-jevgvhGpqJq0ShAjPj/e+46K0ltc7+tY8kV9GNCrkHA=";
    };
    aarch64-darwin = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/${wholeVersion}/darwin-arm/Antigravity.zip";
      hash = "sha256-dIziiU5qJlFyRgahuRfp1pWgN5NfL6xmaTmr9/2MWo0=";
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
