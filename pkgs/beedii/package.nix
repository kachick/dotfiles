{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation rec {
  pname = "beedii";
  version = "1.0.0";

  src = fetchzip {
    url = "https://github.com/webkul/beedii/releases/download/v${version}/beedii.zip";
    hash = "sha256-MefkmWl7LdhQiePpixKcatoIeOTlrRaO3QA9xWAxJ4Q=";
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall

    install -Dm444 Fonts/*.ttf -t $out/share/fonts/truetype/${pname}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Free Hand Drawn Emoji Font";
    homepage = "https://github.com/webkul/beedii";
    license = licenses.cc0;
    platforms = platforms.all;
    maintainers = with maintainers; [ kachick ];
  };
}
