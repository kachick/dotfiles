{
  pkgs,
  lib,
  makeWrapper,
  ...
}:
pkgs.buildGo124Module (finalAttrs: {
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

  vendorHash = "sha256-429N7L6kn4XPXHaPvP9BxbwigOSVYl/B3K8fylmVkzc=";
  src =
    with lib.fileset;
    toSource {
      root = ../../.;
      fileset = unions [
        ../../go.mod
        ../../go.sum
        ../../internal
        ./.
      ];
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
