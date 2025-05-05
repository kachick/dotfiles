{
  pkgs,
  lib,
  makeWrapper,
  ...
}:
pkgs.unstable.buildGo124Module (finalAttrs: {
  pname = "git-hooks-commit-msg";
  version = "0.0.1";

  nativeBuildInputs = [
    makeWrapper
  ];

  wrapperPath = lib.makeBinPath (
    with pkgs;
    [
      typos
      unstable.gitleaks
      my.run_local_hook
    ]
  );

  postFixup = ''
    wrapProgram $out/bin/${finalAttrs.meta.mainProgram} \
      --prefix PATH : "${finalAttrs.wrapperPath}"
  '';

  vendorHash = "sha256-UfbZbWvTVbhNVDIVF9osq+mnaIeXAGO6ysdCUV9GZEI=";
  src =
    with lib.fileset;
    toSource rec {
      root = ../../.;
      # Don't just use `fileset.gitTracked root`, then always rebuild even if just changed the README.md
      fileset = intersection (gitTracked root) (unions [
        ../../go.mod
        ../../go.sum
        ../../internal
        ./.
      ]);
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
    description = "Git hook for commit-msg. See GH-325";
    mainProgram = finalAttrs.pname;
  };
})
