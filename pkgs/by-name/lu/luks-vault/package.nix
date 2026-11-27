{
  lib,
  buildGo127Module,
  makeWrapper,
  cryptsetup,
  fzf,
  gum,
  systemd,
  udisks,
  util-linux,
  xdg-utils,
}:

buildGo127Module (finalAttrs: {
  pname = "luks-vault";
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
        (difference ./. (maybeMissing ./README.md))
      ];
    };

  subPackages = [
    "pkgs/by-name/lu/${finalAttrs.pname}"
  ];

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
  ];

  # Rename the built binary to `vault` while keeping the Nix package name `luks-vault`
  # so it does not collide with HashiCorp `pkgs.vault` in nixpkgs.
  postInstall = ''
    mv $out/bin/${finalAttrs.pname} $out/bin/${finalAttrs.meta.mainProgram}
  '';

  postFixup = ''
    wrapProgram $out/bin/${finalAttrs.meta.mainProgram} \
      --prefix PATH : "${
        lib.makeBinPath [
          cryptsetup
          fzf
          gum
          systemd
          udisks
          util-linux
          xdg-utils
        ]
      }"
  '';

  meta = {
    description = "Mini-TUI and CLI for OS-standard LUKS2 container files";
    mainProgram = "vault";
  };
})
