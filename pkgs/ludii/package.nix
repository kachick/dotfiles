{
  lib,
  stdenvNoCC,
  fetchurl,
  jdk,
  jre,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  curl,
  ripgrep,
  common-updater-scripts,
  writeShellApplication,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ludii";
  version = "1.3.14";

  # Prefer official release assets from ludii.games.
  # - GitHub repository lacks versioned tags except v1.3.14
  # - The Ludii*-src.jar from ludii.games does not contain PlayerDesktop/build.xml
  # We might build from source in the future if upstream continues to provide git tags in new versions such as v1.3.14: https://github.com/Ludeme/Ludii/issues/33
  src = fetchurl {
    url = "https://ludii.games/downloads/Ludii-${finalAttrs.version}.jar";
    hash = "sha256-JIqL3oAfNHvDgKSVf9tIAStL3yNKVZHJv3R5kT1zBo4=";
  };

  nativeBuildInputs = [
    jdk
    makeWrapper
    copyDesktopItems # TODO: Consider darwin desktopItems
  ];

  unpackPhase = ''
    "${jdk}/bin/jar" xf "$src"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"

    install -Dm444 "$src" "$out/share/java/Ludii.jar"
    install -Dm444 ludii-logo-64x64.png "$out/share/icons/hicolor/64x64/apps/ludii.png"

    makeWrapper "${jre}/bin/java" "$out/bin/Ludii" \
      --add-flags "-jar $out/share/java/Ludii.jar"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "Ludii";
      genericName = "Ludii";
      desktopName = "Ludii";
      comment = "General game system";
      icon = "ludii";
      exec = "Ludii";
      categories = [ "Game" ];
      startupWMClass = "app-StartDesktopApp";
    })
  ];

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    help="$("$out/bin/Ludii" --help)"
    [[ "$help" == *"Show this help message"* ]]

    runHook postInstallCheck
  '';

  passthru = {
    updateScript = lib.getExe (writeShellApplication {
      name = "${finalAttrs.pname}-updater";

      runtimeInputs = [
        curl
        ripgrep
        common-updater-scripts
      ];

      runtimeEnv = {
        PNAME = finalAttrs.pname;
      };

      text = ''
        # Avoid "rg --max-count=1"; it can cause an unstable curl exit code 23 error.
        versions="$(
          curl --silent --show-error --fail 'https://ludii.games/download.php' |
            rg --only-matching --replace='$1' 'downloads\/Ludii-(\S+?)\.jar".+Ludii player'
        )"
        new_version="$(head -n 1 <<< "$versions")"
        update-source-version "$PNAME" "$new_version" --ignore-same-version --print-changes
      '';
    });
  };

  meta = {
    description = "General game system";
    homepage = "http://ludii.games";
    sourceProvenance = with lib.sourceTypes; [
      binaryBytecode
    ];
    license = lib.licenses.cc-by-nc-nd-40;
    mainProgram = "Ludii";
    maintainers = with lib.maintainers; [
      kachick
    ];
    platforms = lib.platforms.all;
  };
})
