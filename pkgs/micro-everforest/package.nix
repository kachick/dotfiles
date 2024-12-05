{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  name = "micro-everforest";
  src = fetchFromGitHub {
    owner = "atomashevic";
    repo = "everforest-micro";
    rev = "3a1844eb88e58c582ac902e27d7cc1b33f43199b";
    sha256 = "sha256-WRjORWRo2/mHhLppn8QDEdLp98g2jbG8cnGB4WNNL1c=";
  };

  buildPhase = ''
    mkdir $out
    mkdir $out/colorschemes
  '';

  installPhase = ''
    cp everforest.micro $out/colorschemes
  '';

  meta = {
    # https://github.com/atomashevic/everforest-micro/blob/3a1844eb88e58c582ac902e27d7cc1b33f43199b/LICENSE
    license = lib.licenses.mit;
  };
}
