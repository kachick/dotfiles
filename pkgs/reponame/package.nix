{ pkgs, lib, ... }:
pkgs.unstable.buildGo124Module (finalAttrs: {
  pname = "reponame";
  version = "0.0.1";
  vendorHash = "sha256-t11Jl93X0006vxwp1UuHm03lmeaAGbgGFwT98OsLfKw=";
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
