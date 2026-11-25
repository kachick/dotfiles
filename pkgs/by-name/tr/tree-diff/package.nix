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

  vendorHash = null;
  src =
    with lib.fileset;
    toSource {
      root = ../../../../.;
      fileset = unions [
        ../../../../go.mod
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

  meta = {
    description = "Compare and visualize file tree differences across two directories";
    mainProgram = finalAttrs.pname;
  };
})
