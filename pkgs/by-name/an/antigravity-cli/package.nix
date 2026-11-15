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
  version = "1.5.10";
  buildId = "6396072550072320";
  wholeVersion = "${version}-${buildId}";

  throwSystem = throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}";

  sourceData = {
    x86_64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha256-pfqTKimi/zFK1UdNqobkpEqLAzQD4RqVWAzW4EUAxaU=";
    };
    aarch64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha256-8c41LRbL+jKV2dGfRk5XUwaCPZU2eDM2KBcnfJpiIP4=";
    };
    aarch64-darwin = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha256-2jKvSKG40yvS5BNB3Ij8i/2BsTynuMI4N0li28cmNYA=";
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
