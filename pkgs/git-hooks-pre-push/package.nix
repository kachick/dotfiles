{
  pkgs,
  lib,
  buildGoModule,
  makeWrapper,
  ...
}:

buildGoModule (finalAttrs: {
  pname = "git-hooks-pre-push";
  version = "0.0.1";

  nativeBuildInputs = [
    makeWrapper
  ];

  wrapperPath = lib.makeBinPath (
    with pkgs;
    [
      gitMinimal
      unstable.typos
      unstable.gitleaks
      my.run_local_hook
    ]
  );

  postFixup = ''
    wrapProgram $out/bin/${finalAttrs.meta.mainProgram} \
      --prefix PATH : "${finalAttrs.wrapperPath}"
  '';

  vendorHash = "sha256-dh3DiEjrfqO3FrQRMUqGiRQoiosIvTheUWqFf2gRh2w=";
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
    description = "GH-540 and GH-699";
    mainProgram = finalAttrs.pname;
  };
})
