{
  pkgs,
  lib,
  ...
}:
pkgs.buildGo124Module (finalAttrs: {
  pname = "run_local_hook";
  version = "0.0.1";
  vendorHash = "sha256-rIbm+hhJq6+WbI+4Uk8vjFIJd6dMJTRBBQOf0QBqjAc=";

  # Don't add dependencies as possible to keep simple nix code.
  # For example, git should be because of this is a git hook

  src =
    with lib.fileset;
    toSource rec {
      root = ../../.;
      # Don't just use `fileset.gitTracked root`, then always rebuild even if just changed the README.md
      fileset = intersection (gitTracked root) (unions [
        ../../go.mod
        ../../go.sum
        ../../internal
        ./.
      ]);
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
