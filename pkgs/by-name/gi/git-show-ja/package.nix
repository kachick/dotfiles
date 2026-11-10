{
  lib,
  buildGo127Module,
  ...
}:

buildGo127Module (finalAttrs: {
  pname = "git-show-ja";
  version = "0.0.1";

  __structuredAttrs = true;

  vendorHash = "sha256-2VmZeKyTS3R0cLPtjPYqz3AhJEOIqYh2wAGZotkaTOo=";
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
    "pkgs/by-name/gi/${finalAttrs.pname}"
  ];

  env.CGO_ENABLED = 0;

  passthru.shared-gomod = true;

  meta = {
    description = "Show git commit with Japanese translation appended to commit message";
    mainProgram = finalAttrs.pname;
  };
})
