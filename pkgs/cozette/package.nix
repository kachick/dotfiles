# This package aims better PSF packaging than upstream
# See related links
# - https://github.com/the-moonwitch/Cozette/issues/122
# - https://github.com/NixOS/nixpkgs/pull/301440
# - https://github.com/NixOS/nixpkgs/pull/371226
# - https://github.com/NixOS/nixpkgs/pull/409810

{
  lib,
  pkgs,
  stdenvNoCC,
  fetchzip,
  fetchgit,
}:

let
  aur = fetchgit {
    url = "https://aur.archlinux.org/psf-cozette.git";
    rev = "1c0d5429310f21abf7dbfc358198f250d77fb0bd";
    hash = "sha256-dZ+ayjR2tzUtjgN1peYBEcQgHIZE/K79IvWDBafP6eE=";
  };

  bitsnpicas = pkgs.callPackage ../bitsnpicas/package.nix { };
in
stdenvNoCC.mkDerivation rec {
  pname = "cozette";
  version = "1.29.0";

  src = fetchzip {
    url = "https://github.com/slavfox/Cozette/releases/download/v.${version}/CozetteFonts-v-${
      builtins.replaceStrings [ "." ] [ "-" ] version
    }.zip";
    hash = "sha256-DHUnCzp6c3d57cfkO2kH+czXRiqRWn6DBTo9NVTghQ0=";
  };

  nativeBuildInputs = [
    bitsnpicas
  ];

  buildPhase = ''
    bitsnpicas convertbitmap -sr '${aur}/codepoints.set' -f psf -o cozette_hidpi_adjusted.psf cozette_hidpi.bdf
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 *.ttf -t $out/share/fonts/truetype
    install -Dm644 *.otf -t $out/share/fonts/opentype
    install -Dm644 *.bdf -t $out/share/fonts/misc
    install -Dm644 *.otb -t $out/share/fonts/misc
    install -Dm644 *.woff -t $out/share/fonts/woff
    install -Dm644 *.woff2 -t $out/share/fonts/woff2
    install -Dm644 *.psf -t "$out/share/consolefonts"

    runHook postInstall
  '';

  meta = {
    description = "Bitmap programming font optimized for coziness";
    homepage = "https://github.com/slavfox/cozette";
    changelog = "https://github.com/slavfox/Cozette/blob/v.${version}/CHANGELOG.md";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [
      kachick
    ];
  };
}
