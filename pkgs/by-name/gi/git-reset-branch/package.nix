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
  pname = "git-reset-branch";
  version = "0.0.1";

  __structuredAttrs = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  nativeCheckInputs = [
    pkgs.gitMinimal
  ];

  wrapperPath = lib.makeBinPath (
    with pkgs;
    [
      gitMinimal
    ]
  );

  postFixup = ''
    wrapProgram $out/bin/${finalAttrs.meta.mainProgram} \
      --prefix PATH : "${finalAttrs.wrapperPath}"
  '';

  vendorHash = "sha256-GYimZjkyAkmPMQ48wAFwNKCW8pExXXlaX44jZ/HE/nI=";
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
    "pkgs/by-name/gi/${finalAttrs.pname}"
  ];

  env.CGO_ENABLED = 0;

  passthru.shared-gomod = true;

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "Safely reset a local git branch to remote tracking branch with backup";
    mainProgram = finalAttrs.pname;
  };
})
