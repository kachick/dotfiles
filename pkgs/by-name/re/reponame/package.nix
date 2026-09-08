{
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.unstable) buildGo127Module;
in
buildGo127Module (finalAttrs: {
  pname = "reponame";
  version = "0.0.1";

  __structuredAttrs = true;

  vendorHash = "sha256-4s+s3bSoAHe4rr5WDuFHxy6uUC3+SkjwqM8+SBZWb9o=";
  src =
    with lib.fileset;
    toSource {
      root = ../../../../.;
      fileset = unions [
        ../../../../go.mod
        ../../../../go.sum
        ../../../../internal
        ./.
      ];
    };

  subPackages = [
    "pkgs/by-name/re/${finalAttrs.pname}"
  ];

  env.CGO_ENABLED = 0;

  passthru.shared-gomod = true;

  meta = {
    description = "OWNER/REPO => REPO, REPO => REPO";
    mainProgram = finalAttrs.pname;
  };
})
