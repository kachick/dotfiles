{
  buildGo127Module,
  gitMinimal,
  lib,
  makeWrapper,
  typos,
  betterleaks,
  ...
}:

buildGo127Module (finalAttrs: {
  pname = "git-hooks-pre-push";
  version = "0.0.1";

  __structuredAttrs = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  wrapperPath = lib.makeBinPath [
    gitMinimal
    typos
    betterleaks
  ];

  postFixup = ''
    wrapProgram $out/bin/${finalAttrs.meta.mainProgram} \
      --prefix PATH : "${finalAttrs.wrapperPath}"
  '';

  vendorHash = "sha256-k/qRQykTmtKBdYeT1vtKXNVTjPkhzjYeJgiXR3zQ/js=";
  src =
    with lib.fileset;
    toSource {
      root = ../../../../.;
      fileset = unions [
        ../../../../go.mod
        ../../../../go.sum
        ../../../../internal
        (difference ./. (maybeMissing ./README.md))
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
