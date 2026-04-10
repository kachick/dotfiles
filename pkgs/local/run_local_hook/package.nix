{
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.unstable) buildGo126Module;
in
buildGo126Module (finalAttrs: {
  pname = "run_local_hook";
  version = "0.0.1";
  vendorHash = "sha256-+Mp7aiunp8ylIEUIaO6a2IONbramaDhD+qUSruvdscI=";

  # Don't add dependencies as possible to keep simple nix code.
  # For example, git should be because of this is a git hook

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
    description = "GH-545. Run local git hook from global hook";
    mainProgram = finalAttrs.pname;
  };
})
