{
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs) buildGo127Module;
in
buildGo127Module (finalAttrs: {
  pname = "plamo-trans";
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
    "pkgs/by-name/pl/${finalAttrs.pname}"
  ];

  env.CGO_ENABLED = 0;

  passthru.shared-gomod = true;

  meta = {
    description = "Translate text using local PLaMo-3-Translate via llama-server";
    mainProgram = finalAttrs.pname;
  };
})
