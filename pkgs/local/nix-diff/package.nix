{
  lib,
  pkgs,
  makeWrapper,
  unstable,
}:

let
  inherit (pkgs.unstable) buildGo126Module;
in
buildGo126Module (finalAttrs: {
  pname = "nix-diff";
  version = "0.0.1";

  vendorHash = "sha256-8kO79VawdMhdP5JczC9Yh1Dqva7EarOQHHCuuiWNF7U=";

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

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/nix-diff \
      --prefix PATH : ${lib.makeBinPath [ unstable.dix ]}
  '';

  env.CGO_ENABLED = 0;

  meta = {
    description = "Compare nix derivations and report package changes";
    mainProgram = finalAttrs.pname;
  };
})
