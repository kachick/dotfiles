{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "micro-kdl";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "kachick";
    repo = "micro-kdl";
    rev = "v${version}";
    hash = "sha256-vWI7VbcPM2mgNj32txf2tNKgEi+Bbj0+wEjQRz2uu1E=";
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
