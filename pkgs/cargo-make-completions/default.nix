{
  lib,
  stdenv,
  fetchFromGitHub,
  installShellFiles,
}:

stdenv.mkDerivation rec {
  pname = "cargo-make-completions";
  version = "0.37.16";

  src = fetchFromGitHub {
    owner = "sagiegurari";
    repo = "cargo-make";
    rev = version;
    hash = "sha256-OC1HzoEb9OyusYGC5jmEC4qW4U3oGApYvpy5XkZttSg=";
  };

  nativeBuildInputs = [ installShellFiles ];

  installPhase = ''
    installShellCompletion extra/shell/*.bash
  '';

  meta = with lib; {
    description = "cargo-make shell completions which missing in nixpkgs";
    homepage = "https://github.com/sagiegurari/cargo-make";
    license = licenses.asl20;
    platforms = platforms.all;
  };
}
