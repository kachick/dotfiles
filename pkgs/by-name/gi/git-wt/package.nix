{
  buildGo127Module,
  direnv,
  fzf,
  gitMinimal,
  gum,
  lib,
  local,
  makeWrapper,
  ...
}:

buildGo127Module (finalAttrs: {
  pname = "git-wt";
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
    gum
    local.git-log-fzf
  ];

  postFixup = ''
    wrapProgram $out/bin/${finalAttrs.meta.mainProgram} \
      --prefix PATH : "${finalAttrs.wrapperPath}"
  '';

  vendorHash = "sha256-k/qRQykTmtKBdYeT1vtKXNVTjPkhzjYeJgiXR3zQ/js=";
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
    description = "Manage flat git worktrees in clean-bare repositories";
    mainProgram = finalAttrs.pname;
  };
})
