{
  pkgs,
  lib,
  makeWrapper,
  ...
}:
pkgs.unstable.buildGo124Module (finalAttrs: {
  pname = "git-hooks-pre-push";
  version = "0.0.1";

  nativeBuildInputs = [
    makeWrapper
  ];

  wrapperPath = lib.makeBinPath (
    with pkgs;
    [
      git
      typos
      unstable.gitleaks
      my.run_local_hook
    ]
  );

  postFixup = ''
    wrapProgram $out/bin/${finalAttrs.meta.mainProgram} \
      --prefix PATH : "${finalAttrs.wrapperPath}"
  '';

  vendorHash = "sha256-A6cuG2jPwFsHABTLjgYhOMULTqhdJ4RR1XRro898CxE=";
  src = lib.fileset.toSource rec {
    root = ../../.;
    fileset = lib.fileset.gitTracked root;
  };

  subPackages = [
    "pkgs/${finalAttrs.pname}"
  ];

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X main.TyposConfigPath=${../../typos.toml}"
  ];

  meta = {
    description = "GH-540 and GH-699";
    mainProgram = finalAttrs.pname;
  };
})
