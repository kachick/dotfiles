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
  vendorHash = "sha256-nagxuHQ58Dd56NPHqPzZq/l2E9kVV2l00pKeLm2m69Y=";
  proxyVendor = true;
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
