{
  stdenvNoCC,
  fetchurl,
  antigravity-cli,
  writeShellApplication,
  curl,
  jq,
  gnused,
  nix,
}:

let
  version = "1.5.6";
  buildId = "6104046214447104";
  wholeVersion = "${version}-${buildId}";

  throwSystem = throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}";

  sourceData = {
    x86_64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha256-m4u+eMsGi4HM3mwpnz9bvlYijyOC/jjmRrYowfYKA6Y=";
    };
    aarch64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha256-pEMkGkdOQGIc4LNB5znVW4p+gLFUfgU2o8AQZkp8uJM=";
    };
    aarch64-darwin = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha256-02kOAKPBCzT/zEDWCy2aMvirPUK7qgPXZ+oG290/bmA=";
    };
  };
in
antigravity-cli.overrideAttrs (old: {
  inherit version;

  src = sourceData.${stdenvNoCC.hostPlatform.system} or throwSystem;

  passthru = (old.passthru or { }) // {
    inherit wholeVersion;
    updateScript = writeShellApplication {
      name = "antigravity-cli-updater";

      runtimeInputs = [
        curl
        jq
        gnused
        nix
      ];

      text = builtins.readFile ./update.bash;
    };
  };
})
