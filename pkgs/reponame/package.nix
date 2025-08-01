{
  pkgs,
  lib,
  ...
}:
pkgs.buildGo124Module (finalAttrs: {
  pname = "reponame";
  version = "0.0.1";
  vendorHash = "sha256-CGAwDKktyQQR+3jXTYksLI68j15+0rs7188/rsTJep0=";
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
