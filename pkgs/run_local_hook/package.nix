{
  lib,
  buildGoModule,
  ...
}:

buildGoModule (finalAttrs: {
  pname = "run_local_hook";
  version = "0.0.1";
  vendorHash = "sha256-bLT7ieKcVkUPhqnP5tfYXnHwlvzjNuC3tLV16wK3x20=";

  # Don't add dependencies as possible to keep simple nix code.
  # For example, git should be because of this is a git hook

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
    description = "GH-545. Run local git hook from global hook";
    mainProgram = finalAttrs.pname;
  };
})
