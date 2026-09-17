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
  version = "1.2.5";
  buildId = "4931130160447488";
  wholeVersion = "${version}-${buildId}";

  throwSystem = throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}";

  sourceData = {
    x86_64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha256-5FDKq1aCrMkgchsEzw9oYMMT0fUpa8bknXnNOEOALmU=";
    };
    aarch64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha256-DJ+6bVHZi9QPh77aQ/vHXtyWV4OCyvTsLvohf3Ud/bg=";
    };
    aarch64-darwin = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha256-s3SV7r5T4cVl3W13vdHTumAyFrXTrN2vsYX5fTX9+es=";
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

      text = ''
        set -euo pipefail

        packageFile="pkgs/by-name/an/antigravity-cli/package.nix"
        baseUrl="https://storage.googleapis.com/antigravity-public/antigravity-cli"

        currentVersion="$(sed -n 's/.*version = "\([^"]*\)";.*/\1/p' "$packageFile")"
        latestVersion="$(curl -sSfL "$baseUrl/latest")"

        if [[ "$currentVersion" == "$latestVersion" ]]; then
          echo "antigravity-cli is up-to-date: $currentVersion"
          exit 0
        fi

        echo "Updating antigravity-cli: $currentVersion -> $latestVersion"

        manifestUrl="$baseUrl/$latestVersion/manifest.json"
        manifest="$(curl -sSfL "$manifestUrl")"

        latestWholeVersion="$(echo "$manifest" | jq -r '.platforms."linux-x64".url' | cut -d/ -f6)"
        latestBuildId="''${latestWholeVersion#*-}"
        currentBuildId="$(sed -n 's/.*buildId = "\([^"]*\)";.*/\1/p' "$packageFile")"

        sed -i "s/version = \"$currentVersion\";/version = \"$latestVersion\";/" "$packageFile"
        sed -i "s/buildId = \"$currentBuildId\";/buildId = \"$latestBuildId\";/" "$packageFile"

        x86_64_linux_url="$(echo "$manifest" | jq -r '.platforms."linux-x64".url')"
        aarch64_linux_url="$(echo "$manifest" | jq -r '.platforms."linux-arm".url')"
        aarch64_darwin_url="$(echo "$manifest" | jq -r '.platforms."darwin-arm".url')"

        x86_64_linux_hash="$(nix store prefetch-file --json --hash-type sha256 "$x86_64_linux_url" | jq -r .hash)"
        aarch64_linux_hash="$(nix store prefetch-file --json --hash-type sha256 "$aarch64_linux_url" | jq -r .hash)"
        aarch64_darwin_hash="$(nix store prefetch-file --json --hash-type sha256 "$aarch64_darwin_url" | jq -r .hash)"

        sed -i "/x86_64-linux = fetchurl/,/};/ s|hash = \"[^\"]*\";|hash = \"$x86_64_linux_hash\";|" "$packageFile"
        sed -i "/aarch64-linux = fetchurl/,/};/ s|hash = \"[^\"]*\";|hash = \"$aarch64_linux_hash\";|" "$packageFile"
        sed -i "/aarch64-darwin = fetchurl/,/};/ s|hash = \"[^\"]*\";|hash = \"$aarch64_darwin_hash\";|" "$packageFile"

        echo "antigravity-cli updated to $latestVersion ($latestWholeVersion)"
      '';
    };
  };
})
