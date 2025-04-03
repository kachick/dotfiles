{ pkgs, lib, ... }:
pkgs.unstable.buildGo124Module (finalAttrs: {
  pname = "reponame";
  version = "0.0.1";
  vendorHash = "sha256-A6cuG2jPwFsHABTLjgYhOMULTqhdJ4RR1XRro898CxE=";
  src = lib.fileset.toSource rec {
    root = ../../.;
    fileset = lib.fileset.gitTracked root;
  };

  subPackages = [
    "pkgs/${finalAttrs.pname}"
  ];

  env.CGO_ENABLED = 0;

  meta = {
    description = "OWNER/REPO => REPO, REPO => REPO";
    mainProgram = finalAttrs.pname;
  };
})
