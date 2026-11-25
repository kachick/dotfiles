{
  lib,
  buildGo127Module,
  ...
}:

buildGo127Module (finalAttrs: {
  pname = "dot-writable-sync";
  version = "0.0.1";

  __structuredAttrs = true;

  vendorHash = null;
  src =
    with lib.fileset;
    toSource {
      root = ../../../../.;
      fileset = unions [
        ../../../../go.mod
        ../../../../internal
        ./.
      ];
    };

  subPackages = [
    "pkgs/by-name/do/${finalAttrs.pname}"
  ];

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "Repository-internal Home Manager helper to initialize writable config files";
    mainProgram = finalAttrs.pname;
  };
})
