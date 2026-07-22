{
  lib,
  stdenvNoCC,
  fetchzip,
  installFonts,
}:
stdenvNoCC.mkDerivation rec {
  pname = "ibm-plex-sans-jp";
  version = "3.0.0";

  # REVISIT: https://github.com/NixOS/nixpkgs/pull/505549
  # As of 2026-04-22, the upstream PR combines all IBM Plex fonts into a single package,
  # which leads to unnecessary disk bloat. We use individual packages here to minimize the footprint.
  src = fetchzip {
    url = "https://github.com/IBM/plex/releases/download/@ibm/plex-sans-jp@${version}/ibm-plex-sans-jp.zip";
    hash = "sha256-2BbhqsutMXEoS2JoZjJprrElIpFa9lgvPaM65pnYdfs=";
    stripRoot = true;
  };

  # Pick otf hinted as source root to avoid collisions with unhinted and ttf variants
  sourceRoot = "source/fonts/complete/otf/hinted";

  nativeBuildInputs = [ installFonts ];

  # Unnecessary for dotfiles
  dontInstallWebfonts = true;

  meta = {
    description = "IBM Plex Sans JP";
    homepage = "https://github.com/IBM/plex";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
