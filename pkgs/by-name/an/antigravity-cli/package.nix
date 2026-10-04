{
  stdenvNoCC,
  fetchurl,
  unstable,
  writeShellApplication,
  curl,
  jq,
  gnused,
  nix,
}:

let
  version = "1.2.17";
  buildId = "4762618829864960";
  wholeVersion = "${version}-${buildId}";

  throwSystem = throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}";

  sourceData = {
    x86_64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha256-FQmgUgSUfPrWl0h93JfsiQ2GeF+tOvcoDpw/vonsqko=";
    };
    aarch64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha256-1lM1tEuxwPvLPPlEwJz/ZLR/QCdm8tgd4aXGZyuMvjk=";
    };
    aarch64-darwin = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha256-PvZzJKQuaGMUU6nlx8jhJlG/CFqLnzK7sSZXPcOv2u8=";
    };
  };
in
unstable.antigravity-cli.overrideAttrs (old: {
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
