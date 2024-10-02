{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  name = "micro-nordcolors";
  src = fetchFromGitHub {
    owner = "KiranWells";
    repo = "micro-nord-tc-colors";
    rev = "f63c855735f755704c25c958abe45f12a4b2c8d3";
    sha256 = "sha256-giCansV+9oa2OSQlt7DkLtL7B7sD00JUBaS9YsbJ9aU=";
  };

  buildPhase = ''
    mkdir $out
  '';

  installPhase = ''
    cp repo.json $out
    cp *.lua $out
    cp -rf ./colorschemes $out/colorschemes
    cp -rf ./help $out/help
  '';
}
