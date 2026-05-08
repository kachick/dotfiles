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

  vendorHash = "sha256-uAEDdBuihA9qZVZjcayToV1MgiWi5VQVhmC6lR/V6Qg=";

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

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/nix-diff \
      --prefix PATH : ${lib.makeBinPath [ unstable.dix ]}
  '';

  env.CGO_ENABLED = 0;

  passthru.shared-gomod = true;

  meta = {
    description = "Compare nix derivations and report package changes";
    mainProgram = finalAttrs.pname;
  };
})
