{
  pkgs,
  lib,
  ...
}:
pkgs.buildGo124Module (finalAttrs: {
  pname = "reponame";
  version = "0.0.1";
  vendorHash = "sha256-mWY528nC/bYXO6ddHkq7qnZT854Gg04gHdqdr9B3j8Y=";
  src =
    with lib.fileset;
    toSource {
      root = ../../.;
      fileset = unions [
        ../../go.mod
        ../../go.sum
        ../../internal
        ./.
      ];
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
