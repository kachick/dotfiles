{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

let
  version = "0.0.3";
  src = fetchFromGitHub {
    owner = "hougesen";
    repo = "kdlfmt";
    rev = "v${version}";
    hash = "sha256-qD1NYLHGmVRgV6pPXbvJ9NWDg/wVLWJY4hUsOLDlKh0=";
  };
in
rustPlatform.buildRustPackage {
  inherit version src;

  pname = "kdlfmt";

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  meta = with lib; {
    description = "A formatter for kdl documents.";
    homepage = "https://github.com/hougesen/kdlfmt";
    changelog = "https://github.com/hougesen/kdlfmt/releases/tag/${src.rev}";
    license = licenses.mit;
    maintainers = with maintainers; [ kachick ];
    mainProgram = "kdlfmt";
  };
}
