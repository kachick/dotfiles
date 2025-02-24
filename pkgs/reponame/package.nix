{ pkgs, ... }:
pkgs.unstable.buildGo124Module rec {
  pname = "reponame";
  version = "0.0.1";
  default = pname;
  vendorHash = "sha256-uPqabZgQGQulf+F3BvMLhv4O0h5jOq12F7K60u5xjtA=";
  src = ./.;

  env.CGO_ENABLED = 0;

  meta = {
    description = "OWNER/REPO => REPO, REPO => REPO";
    mainProgram = pname;
  };
}
