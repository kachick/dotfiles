{
  lib,
  stdenvNoCC,
  fetchzip,
  installFonts,
}:
stdenvNoCC.mkDerivation rec {
  pname = "ibm-plex-mono";
  version = "1.1.0";

  # REVISIT: https://github.com/NixOS/nixpkgs/pull/505549
  # As of 2026-04-22, the upstream PR combines all IBM Plex fonts into a single package,
  # which leads to unnecessary disk bloat. We use individual packages here to minimize the footprint.
  src = fetchzip {
    url = "https://github.com/IBM/plex/releases/download/@ibm/plex-mono@${version}/ibm-plex-mono.zip";
    hash = "sha256-OwUmrPfEehLDz0fl2ChYLK8FQM2p0G1+EMrGsYEq+6g=";
    stripRoot = true;
  };

  nativeBuildInputs = [ installFonts ];

  meta = {
    description = "IBM Plex Mono";
    homepage = "https://github.com/IBM/plex";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
