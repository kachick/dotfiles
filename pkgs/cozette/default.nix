{
  lib,
  stdenvNoCC,
  fetchzip,
}:

# Patched because of nixpkgs does not include psf
# https://github.com/NixOS/nixpkgs/blob/41d21a82c38e226e234e16f4ff213b3fcf85e6e9/pkgs/data/fonts/cozette/default.nix#L1C1-L33C2
stdenvNoCC.mkDerivation rec {
  pname = "cozette";
  version = "1.25.1";

  src = fetchzip {
    url = "https://github.com/slavfox/Cozette/releases/download/v.${version}/CozetteFonts-v-${
      builtins.replaceStrings [ "." ] [ "-" ] version
    }.zip";
    hash = "sha256-Cnl7DTPcZmCRM06qe7WXfZorok3uUNYcB9bR/auzCao=";
  };

  installPhase = ''
    runHook preInstall

    install -Dm644 *.ttf -t $out/share/fonts/truetype
    install -Dm644 *.otf -t $out/share/fonts/opentype
    install -Dm644 *.bdf -t $out/share/fonts/misc
    install -Dm644 *.otb -t $out/share/fonts/misc
    install -Dm644 *.woff -t $out/share/fonts/woff
    install -Dm644 *.woff2 -t $out/share/fonts/woff2
    install -Dm644 *.psf -t $out/share/consolefonts

    runHook postInstall
  '';

  meta = with lib; {
    description = "Bitmap programming font optimized for coziness";
    homepage = "https://github.com/slavfox/cozette";
    changelog = "https://github.com/slavfox/Cozette/blob/v.${version}/CHANGELOG.md";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [
      brettlyons
      kachick
    ];
  };
}
