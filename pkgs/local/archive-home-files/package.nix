{
  pkgs,
  lib,
  pinned,
  makeWrapper,
  ...
}:

let
  inherit (pkgs.unstable) buildGo126Module;
  keys = import ../../../config/ssh/keys.nix;
  betterleaksConfig = ../../../config/betterleaks/.betterleaks.toml;
in
buildGo126Module (finalAttrs: {
  pname = "archive-home-files";
  version = "0.1.0";

  nativeBuildInputs = [
    makeWrapper
  ];

  wrapperPath = lib.makeBinPath (
    with pkgs;
    [
      gnutar
      ripgrep
      coreutils
      age
      unstable.betterleaks
      pinned.home-manager
    ]
  );

  postFixup = ''
    wrapProgram $out/bin/archive-home-files \
      --prefix PATH : "${finalAttrs.wrapperPath}" \
      --set-default BETTERLEAKS_CONFIG "${betterleaksConfig}" \
      --set-default AGE_RECIPIENTS "${lib.concatStringsSep "," keys}"
  '';

  vendorHash = "sha256-tvq951p9pznSyLeQDYHbo4PvXLR0VrgUXR2j4AW5Ir0=";
  src =
    with lib.fileset;
    toSource {
      root = ../../../.;
      fileset = unions [
        ../../../go.mod
        ../../../go.sum
        ./.
      ];
    };

  env.CGO_ENABLED = 0;

  passthru.shared-gomod = true;

  ldflags = [
    "-s"
    "-w"
  ];

  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/archive-home-files --help > /dev/null
  '';

  meta = {
    description = "Backup and encrypt dotfiles generated with home-manager";
    longDescription = ''
      Backup dotfiles generated with home-manager.
      - Scans for secrets with betterleaks (follows symlinks to Nix store).
      - Encrypts the archive with age using all SSH public keys from config/ssh/keys.nix.
    '';
    mainProgram = "archive-home-files";
  };
})
