{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation {
  pname = "micro-kdl";
  version = "unstable-2024-08-15";

  src = fetchFromGitHub {
    owner = "kachick";
    repo = "micro-kdl";
    rev = "fa014198284ede791afc36ccec5d24c0c7201256";
    hash = "sha256-wS1Ldrhn8dKTXdLM23glDdFrKxAex4aZJSxgYaHN/uA=";
  };

  buildPhase = ''
    mkdir $out
  '';

  installPhase = ''
    cp repo.json $out
    cp kdl.* $out
  '';

  meta = with lib; {
    description = "Micro editor syntax highlighting for KDL";
    homepage = "https://github.com/kachick/micro-kdl";
    license = licenses.mit;
    mainProgram = "micro-kdl";
    platforms = platforms.all;
  };
}
