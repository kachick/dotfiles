{
  bashInteractive,
  bat,
  betterleaks,
  buildGo127Module,
  coreutils,
  direnv,
  eza,
  fzf,
  gh,
  gitMinimal,
  gum,
  installShellFiles,
  lib,
  makeWrapper,
  riffdiff,
  ripgrep,
  stdenv,
  typos,
  ...
}:

buildGo127Module (finalAttrs: {
  pname = "git-x";
  version = "0.0.1";

  __structuredAttrs = true;

  nativeBuildInputs = [
    installShellFiles
    makeWrapper
  ];

  nativeCheckInputs = [
    bashInteractive
    direnv
    fzf
    gitMinimal
  ];

  wrapperPath = lib.makeBinPath [
    bat
    betterleaks
    coreutils
    direnv
    eza
    fzf
    gh
    gitMinimal
    gum
    riffdiff
    ripgrep
    typos
  ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd ${finalAttrs.meta.mainProgram} \
      --bash <("$out/bin/${finalAttrs.meta.mainProgram}" completion bash) \
      --zsh <("$out/bin/${finalAttrs.meta.mainProgram}" completion zsh)
  '';

  postFixup = ''
    wrapProgram $out/bin/${finalAttrs.meta.mainProgram} \
      --prefix PATH : "${finalAttrs.wrapperPath}"
  '';

  vendorHash = null;
  src =
    with lib.fileset;
    toSource {
      root = ../../../../.;
      fileset = unions [
        ../../../../go.mod
        ../../../../internal/plamocache
        (difference ./. (maybeMissing ./README.md))
      ];
    };

  subPackages = [
    "pkgs/by-name/gi/${finalAttrs.pname}"
  ];

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X main.TyposConfigPath=${../../../../typos.toml}"
  ];

  meta = {
    description = "Unified Git and GitHub workflow helper CLI";
    mainProgram = finalAttrs.pname;
  };
})
