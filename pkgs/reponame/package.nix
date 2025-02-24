{ pkgs, ... }:
pkgs.unstable.buildGo124Module rec {
  pname = "reponame";
  version = "0.0.1";
  default = pname;
  vendorHash = "sha256-1wycFQdf6sudxnH10xNz1bppRDCQjCz33n+ugP74SdQ=";
  src = ./.;

  env.CGO_ENABLED = 0;

  meta = {
    description = "OWNER/REPO => REPO, REPO => REPO";
    mainProgram = pname;
  };
}
