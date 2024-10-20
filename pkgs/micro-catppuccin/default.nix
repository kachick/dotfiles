{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  name = "micro-everforest";
  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "micro";
    rev = "2802b32308e5b1a827689c095f11ae604bbc85e6";
    sha256 = "sha256-+Jf32S2CHackdmx+UmEKjx71ZCf4VfnxeA3yzz3MSLQ=";
  };

  buildPhase = ''
    mkdir $out
  '';

  installPhase = ''
    cp -rf src $out/colorschemes
  '';
}
