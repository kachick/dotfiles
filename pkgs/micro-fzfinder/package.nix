{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation rec {
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

  meta = {
    description = "The plugin allows you to integrate fzf to select and search for your project files";
    homepage = "https://github.com/MuratovAS/micro-fzfinder";
    # https://github.com/MuratovAS/micro-fzfinder/blob/7be0adb25d72b557eab9fea5aceaff18d47bff52/LICENSE
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
