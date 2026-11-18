{
  buildGo127Module,
  direnv,
  fzf,
  gitMinimal,
  lib,
  makeWrapper,
  ...
}:

buildGo127Module (finalAttrs: {
  pname = "git-migrate-clean-bare";
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
    direnv
    fzf
    gitMinimal
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
  ];

  meta = {
    description = "Convert standard git repositories into the clean-bare worktree layout";
    mainProgram = finalAttrs.pname;
  };
})
