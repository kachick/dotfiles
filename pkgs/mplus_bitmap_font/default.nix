{
  lib,
  pkgs,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation rec {
  pname = "mplus_bitmap_font";
  version = "2.2.4";

  src = fetchurl {
    url = "https://github.com/coz-m/MPLUS_FONTS/raw/c47fd4ff0a604d1517625a0f3d67e6d64e12d585/obsolete/mplus_bitmap_fonts-2.2.4.tar.gz";
    hash = lib.fakeHash;
    stripRoot = false;
  };

  nativeBuildInputs = with pkgs; [ bdf2psf ];

  buildPhase = ''
    # convert bdf fonts to psf
    build=$(pwd)
    mkdir psf
    cd ${pkgs.bdf2psf}/share/bdf2psf
    for i in $src/fonts_e/mplus_*.bdf $src/fonts_j/mplus_*.bdf; do
      name=$(basename $i .bdf)
      bdf2psf \
        --fb "$i" standard.equivalents \
        ascii.set+useful.set+linux.set 512 \
        "$build/psf/$name.psf"
    done
    cd $build
  '';

  installPhase = ''
    runHook preInstall

    install -Dm444 psf/*.psf -t $out/share/fonts/consolefonts/${pname}

    runHook postInstall
  '';

  meta = with lib; {
    description = "M+ FONTS";
    homepage = "https://github.com/coz-m/MPLUS_FONTS/issues/47#issuecomment-1683804254";
    license = licenses.mplus; # The repository set ofl, but this file looks only including mplus license era files
    platforms = platforms.all;
    maintainers = with maintainers; [ kachick ];
  };
}
