{
  lib,
  buildGoModule,
  ...
}:

buildGoModule (finalAttrs: {
  pname = "reponame";
  version = "0.0.1";
  vendorHash = "sha256-rBq1SoUP6sFsHcEd/+Wr35Id1X3pFMVEfTxQU5jQ8gQ=";
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
