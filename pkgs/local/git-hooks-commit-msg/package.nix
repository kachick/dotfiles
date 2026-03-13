{
  pkgs,
  lib,
  makeWrapper,
  ...
}:

let
  inherit (pkgs.unstable) buildGo126Module;
in
buildGo126Module (finalAttrs: {
  pname = "git-hooks-commit-msg";
  version = "0.0.1";

  nativeBuildInputs = [
    makeWrapper
  ];

  wrapperPath = lib.makeBinPath (
    with pkgs;
    [
      unstable.typos
      unstable.gitleaks
      local.run_local_hook
    ]
  );

  postFixup = ''
    wrapProgram $out/bin/${finalAttrs.meta.mainProgram} \
      --prefix PATH : "${finalAttrs.wrapperPath}"
  '';

  vendorHash = "sha256-nagxuHQ58Dd56NPHqPzZq/l2E9kVV2l00pKeLm2m69Y=";
  proxyVendor = true;
  src =
    with lib.fileset;
    toSource {
      root = ../../../.;
      fileset = unions [
        ../../../go.mod
        ../../../go.sum
        ../../../internal
        ./.
      ];
    };

  subPackages = [
    "pkgs/local/${finalAttrs.pname}"
  ];

  env.CGO_ENABLED = 0;

  passthru.shared-gomod = true;

  ldflags = [
    "-s"
    "-w"
    "-X main.TyposConfigPath=${../../../typos.toml}"
  ];

  meta = {
    description = "Git hook for commit-msg. See GH-325";
    mainProgram = finalAttrs.pname;
  };
})
