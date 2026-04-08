{
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.unstable) buildGo126Module;
in
buildGo126Module (finalAttrs: {
  pname = "reponame";
  version = "0.0.1";
  vendorHash = "sha256-UBBE/UqD1JlQ5xawrJFmlSahNlFvOZ9Rl0orLr1aKSc=";
  src =
    with lib.fileset;
    toSource {
      root = ../../../.;
      fileset = unions [
        ../../../go.mod
        ../../../go.sum
        ../../../internal
        ./.
      ];
    };

  subPackages = [
    "pkgs/local/${finalAttrs.pname}"
  ];

  env.CGO_ENABLED = 0;

  passthru.shared-gomod = true;

  meta = {
    description = "OWNER/REPO => REPO, REPO => REPO";
    mainProgram = finalAttrs.pname;
  };
})
