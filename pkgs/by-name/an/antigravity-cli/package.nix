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
  version = "1.5.13";
  buildId = "5999302598852608";
  wholeVersion = "${version}-${buildId}";

  throwSystem = throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}";

  sourceData = {
    x86_64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha256-f6nMbfDQlWJpPWN8QGqGwbD1KrM2RxSx/S15zGBg1LI=";
    };
    aarch64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha256-Nllq2AOFMf118Ol7W6iWejDy/Wf42cYZWdLkdh17IV8=";
    };
    aarch64-darwin = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha256-HIPj6Ii1QQxEptilRn9+yg11xNVVHIAHa32o3Hc4vZw=";
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
