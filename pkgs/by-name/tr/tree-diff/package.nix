{
  lib,
  buildGo127Module,
  makeWrapper,
  gitMinimal,
  ...
}:

buildGo127Module (finalAttrs: {
  pname = "tree-diff";
  version = "0.0.1";

  __structuredAttrs = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  nativeCheckInputs = [
    gitMinimal
  ];

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
    "pkgs/by-name/tr/${finalAttrs.pname}"
  ];

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
  ];

  # Suffix PATH so user's git and pagers such as riff in PATH stay preferred.
  postFixup = ''
    wrapProgram $out/bin/${finalAttrs.meta.mainProgram} \
      --suffix PATH : "${lib.makeBinPath [ gitMinimal ]}"
  '';

  passthru.shared-gomod = true;

  meta = {
    description = "Compare and visualize file tree differences across two directories";
    mainProgram = finalAttrs.pname;
  };
})
