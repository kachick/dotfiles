{
  lib,
  buildGo127Module,
  ...
}:

buildGo127Module (finalAttrs: {
  pname = "plamo";
  version = "0.0.1";

  __structuredAttrs = true;

  vendorHash = "sha256-k/qRQykTmtKBdYeT1vtKXNVTjPkhzjYeJgiXR3zQ/js=";
  src =
    with lib.fileset;
    toSource {
      root = ../../../../.;
      fileset = unions [
        ../../../../go.mod
        ../../../../go.sum
        ../../../../internal
        (difference ./. (maybeMissing ./README.md))
      ];
    };

  subPackages = [
    "pkgs/by-name/pl/${finalAttrs.pname}"
  ];

  env.CGO_ENABLED = 0;

  passthru.shared-gomod = true;

  # Expose `trans` as a symlink instead of a shell alias so editors, scripts, and non-POSIX shells (e.g. nushell) can call it directly.
  postInstall = ''
    ln -s ${finalAttrs.meta.mainProgram} $out/bin/trans
  '';

  meta = {
    description = "Local PLaMo-3-Translate CLI and service controller";
    mainProgram = finalAttrs.pname;
  };
})
