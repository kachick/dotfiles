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
  version = "1.5.11";
  buildId = "6132547114106880";
  wholeVersion = "${version}-${buildId}";

  throwSystem = throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}";

  sourceData = {
    x86_64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha256-32UsmP31Gah8AXtOHZLz/bZsNE3hbl5oXFlmN7vSgzQ=";
    };
    aarch64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha256-3k/qFfg/QGhcswN0tYM3MY1YNA78yHeaLrFGG2ILafQ=";
    };
    aarch64-darwin = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha256-dNfu0WPiWnfxWbHllaDhfdiDTtVA+N9hJdGImnyIZ3Q=";
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
