{
  bat,
  betterleaks,
  buildGo127Module,
  coreutils,
  direnv,
  eza,
  fzf,
  gh,
  gitMinimal,
  gum,
  lib,
  makeWrapper,
  riffdiff,
  ripgrep,
  typos,
  ...
}:

buildGo127Module (finalAttrs: {
  pname = "gitx";
  version = "0.0.1";

  __structuredAttrs = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  nativeCheckInputs = [
    direnv
    fzf
    gitMinimal
  ];

  wrapperPath = lib.makeBinPath [
    bat
    betterleaks
    coreutils
    direnv
    eza
    fzf
    gh
    gitMinimal
    gum
    riffdiff
    ripgrep
    typos
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
    description = "Unified Git and GitHub workflow helper CLI";
    mainProgram = finalAttrs.pname;
  };
})
