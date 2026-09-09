{
  pkgs,
  lib,
  makeWrapper,
  ...
}:

let
  inherit (pkgs.unstable) buildGo127Module;
in
buildGo127Module (finalAttrs: {
  pname = "git-hooks-pre-push";
  version = "0.0.1";

  __structuredAttrs = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  wrapperPath = lib.makeBinPath (
    with pkgs;
    [
      gitMinimal
      unstable.typos
      unstable.betterleaks
    ]
  );

  postFixup = ''
    wrapProgram $out/bin/${finalAttrs.meta.mainProgram} \
      --prefix PATH : "${finalAttrs.wrapperPath}"
  '';

  vendorHash = "sha256-OhlqRUzEqC0LBaHS7uES7zdg9nzKCG3E3Kqju+rl9ug=";
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

  ldflags = [
    "-s"
    "-w"
    "-X main.TyposConfigPath=${../../../../typos.toml}"
  ];

  meta = {
    description = "GH-540 and GH-699";
    mainProgram = finalAttrs.pname;
  };
})
