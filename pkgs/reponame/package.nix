{ pkgs, lib, ... }:
pkgs.unstable.buildGo124Module (finalAttrs: {
  pname = "reponame";
  version = "0.0.1";
  vendorHash = "sha256-PSV3nbT1SUxjGvAw98J6PRzNpsxtA1tG6hh0ihT6EA4=";
  src =
    with lib.fileset;
    toSource rec {
      root = ../../.;
      # Don't just use `fileset.gitTracked root`, then always rebuild even if just changed the README.md
      fileset = intersection (gitTracked root) (unions [
        ../../go.mod
        ../../go.sum
        ../../internal
        ./.
      ]);
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
