{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

# Patched because of nixpkgs does not include psf
# https://github.com/NixOS/nixpkgs/blob/41d21a82c38e226e234e16f4ff213b3fcf85e6e9/pkgs/data/fonts/cozette/default.nix#L1C1-L33C2
stdenvNoCC.mkDerivation {
  pname = "inconsolata-psf";
  version = "unstable-2016-05-02";

  src = fetchFromGitHub {
    owner = "xeechou";
    repo = "Inconsolata-psf";
    rev = "75778a3d5b0a05cb492d51120b055e91672b3bf8";
    sha256 = "sha256-kth0ExRdO3dhCd4AnIGh6MGLL3Msfq5+msk9ALs2yCk=";
  };

  installPhase = ''
    runHook preInstall

    install -Dm644 *.psf -t $out/share/consolefonts

    runHook postInstall
  '';

  meta = with lib; {
    description = "Transforming Inconsolata font to psf format for Linux console";
    homepage = "https://github.com/xeechou/Inconsolata-psf";
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = with maintainers; [
      kachick
    ];
  };
}
