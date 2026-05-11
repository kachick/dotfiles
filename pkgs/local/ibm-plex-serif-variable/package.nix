{
  lib,
  stdenvNoCC,
  fetchzip,
  installFonts,
}:
stdenvNoCC.mkDerivation rec {
  pname = "ibm-plex-serif-variable";
  version = "2.0.0";

  # REVISIT: https://github.com/NixOS/nixpkgs/pull/505549
  # As of 2026-04-22, the upstream PR combines all IBM Plex fonts into a single package,
  # which leads to unnecessary disk bloat. We use individual packages here to minimize the footprint.
  src = fetchzip {
    url = "https://github.com/IBM/plex/releases/download/@ibm/plex-serif-variable@${version}/plex-serif-variable.zip";
    hash = "sha256-xhjmeIMT7FAFhfR8fekAxzQEl1hOtPdQ6qsVpnZN6Xg=";
    stripRoot = false;
  };

  nativeBuildInputs = [ installFonts ];

  # Unnecessary for dotfiles
  dontInstallWebfonts = true;

  meta = {
    description = "IBM Plex Serif Variable";
    homepage = "https://github.com/IBM/plex";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
