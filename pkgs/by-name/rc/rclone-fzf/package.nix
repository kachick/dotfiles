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

  meta = {
    description = "List and operate rclone remotes";
    mainProgram = finalAttrs.pname;
    platforms = lib.platforms.linux;
  };
})
