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
  version = "1.5.14";
  buildId = "5302690847260672";
  wholeVersion = "${version}-${buildId}";

  throwSystem = throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}";

  sourceData = {
    x86_64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha256-1YOGMi0gc+lrM/fMMrTpri22Io9YRANpcllnst5Ix7U=";
    };
    aarch64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha256-5faaMSP6xml0swPZogHzgaD7MrPvhp2ROdqF1cr2eio=";
    };
    aarch64-darwin = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha256-sBvdRZHhPd/LDgSb6nSun4PoCCmtz2SqpY9b+xpCWlQ=";
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

  meta = (old.meta or { }) // {
    changelog = "https://antigravity.google/docs/changelog?tab=cli";
  };
})
