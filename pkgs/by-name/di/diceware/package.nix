{
  lib,
  buildGo127Module,
  ...
}:

buildGo127Module (finalAttrs: {
  pname = "diceware";
  version = "0.0.1";

  __structuredAttrs = true;

  vendorHash = null;
  src =
    with lib.fileset;
    toSource {
      root = ../../../../.;
      fileset = unions [
        ../../../../go.mod
        ./.
      ];
    };

  subPackages = [
    "pkgs/by-name/di/${finalAttrs.pname}"
  ];

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
  ];

  # Keep CC-BY-3.0 attribution alongside the binary for public binary cache redistribution.
  postInstall = ''
    install -Dm444 pkgs/by-name/di/${finalAttrs.pname}/NOTICE "$out/share/licenses/${finalAttrs.pname}/NOTICE"
  '';

  meta = {
    description = "Offline passphrase generator using the EFF Large Wordlist";
    license = [
      lib.licenses.mit
      lib.licenses.cc-by-30
    ];
    mainProgram = finalAttrs.pname;
  };
})
