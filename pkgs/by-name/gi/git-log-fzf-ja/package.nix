{
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.unstable) buildGo127Module;
in
buildGo127Module (finalAttrs: {
  pname = "git-log-fzf-ja";
  version = "0.0.1";

  __structuredAttrs = true;

  nativeBuildInputs = [
    pkgs.makeWrapper
  ];

  wrapperPath = pkgs.lib.makeBinPath (
    with pkgs;
    [
      fzf
      gitMinimal
      gh
      bat
      riffdiff
      local.git-log-simple
      local.git-show-ja
    ]
  );

  postFixup = ''
    wrapProgram $out/bin/${finalAttrs.meta.mainProgram} \
      --prefix PATH : "${finalAttrs.wrapperPath}"
  '';

  vendorHash = "sha256-2VmZeKyTS3R0cLPtjPYqz3AhJEOIqYh2wAGZotkaTOo=";
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

  meta = {
    description = "Faster git log searcher with asynchronous Japanese translation preview for large repositories";
    mainProgram = finalAttrs.pname;
  };
})
