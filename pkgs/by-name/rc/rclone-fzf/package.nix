{
  lib,
  buildGo127Module,
  makeWrapper,
  fzf,
  rclone,
  ...
}:

buildGo127Module (finalAttrs: {
  pname = "rclone-fzf";
  version = "0.0.1";

  __structuredAttrs = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  vendorHash = "sha256-8v4EL++G1Di/nBkd/N/nNAEqpDmtjbL6DFHaXPt2JcQ=";
  src =
    with lib.fileset;
    toSource {
      root = ../../../../.;
      fileset = unions [
        ../../../../go.mod
        ../../../../go.sum
        ./.
      ];
    };

  subPackages = [
    "pkgs/by-name/rc/${finalAttrs.pname}"
  ];

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
  ];

  postInstall = ''
    ln -s rclone-fzf $out/bin/rclone-mount
    ln -s rclone-fzf $out/bin/rclone-list-mounted
    wrapProgram $out/bin/rclone-fzf \
      --prefix PATH : ${
        lib.makeBinPath [
          fzf
          rclone
        ]
      }
  '';

  passthru.shared-gomod = true;

  meta = {
    description = "List and operate rclone remotes";
    mainProgram = finalAttrs.pname;
    platforms = lib.platforms.linux;
  };
})
