{ pkgs, ... }:
pkgs.buildGo123Module rec {
  pname = "reponame";
  version = "0.0.1";
  default = pname;
  vendorHash = "sha256-1wycFQdf6sudxnH10xNz1bppRDCQjCz33n+ugP74SdQ=";
  src = ./.;

  meta = {
    description = "kachick/dotfiles => dotfiles, dotfiles => dotfiles";
    mainProgram = pname;
  };
}
