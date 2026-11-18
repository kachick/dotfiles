{
  buildGo127Module,
  eza,
  fzf,
  ghq,
  gitMinimal,
  lib,
  makeWrapper,
  ...
}:

buildGo127Module (finalAttrs: {
  pname = "ghqf";
  version = "0.0.1";

  __structuredAttrs = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  nativeCheckInputs = [
    fzf
    ghq
    gitMinimal
  ];

  wrapperPath = lib.makeBinPath [
    eza
    fzf
    ghq
  ];

  postFixup = ''
    wrapProgram $out/bin/${finalAttrs.meta.mainProgram} \
      --prefix PATH : "${finalAttrs.wrapperPath}"
  '';

  vendorHash = "sha256-8v4EL++G1Di/nBkd/N/nNAEqpDmtjbL6DFHaXPt2JcQ=";
  src =
    with lib.fileset;
    toSource {
      root = ../../../../.;
      fileset = unions [
        ../../../../go.mod
        ../../../../go.sum
        ./.
      ];
    };

  subPackages = [
    "pkgs/by-name/gh/${finalAttrs.pname}"
  ];

  env.CGO_ENABLED = 0;

  passthru.shared-gomod = true;

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "ghq + fzf flat worktree selector";
    mainProgram = finalAttrs.pname;
  };
})
