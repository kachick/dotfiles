{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "micro-fzfinder";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "MuratovAS";
    repo = "micro-fzfinder";
    rev = "v${version}";
    hash = "sha256-/xjGPtadyYjx8chgBDPKc/QinDhxgkyZfihyHyln948=";
  };

  buildPhase = ''
    mkdir $out
  '';

  installPhase = ''
    cp repo.json $out
    cp fzfinder.lua $out
  '';

  meta = with lib; {
    description = "The plugin allows you to integrate fzf to select and search for your project files";
    homepage = "https://github.com/MuratovAS/micro-fzfinder";
    license = licenses.mit;
    mainProgram = "micro-fzfinder";
    platforms = platforms.all;
  };
}
