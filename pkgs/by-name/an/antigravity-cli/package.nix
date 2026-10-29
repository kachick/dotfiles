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
  version = "1.4.10";
  buildId = "5501573669978112";
  wholeVersion = "${version}-${buildId}";

  throwSystem = throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}";

  sourceData = {
    x86_64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha256-7QUmIx45FrbMGwJc81aGLojMA24nw8Xq5aWASV/Hl3M=";
    };
    aarch64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha256-EHt0mcqQAYqytsG2Ns3sQlHf2DZlZSaEXjVL4b/gXro=";
    };
    aarch64-darwin = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha256-Baf8bdNI0gA3h/OnUP/p6bBnxEUEACxqg0QSgx/zDBU=";
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
