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
  gitleaksConfig = ../../../config/gitleaks/.gitleaks.toml;
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
      unstable.gitleaks
      pinned.home-manager
    ]
  );

  postFixup = ''
    wrapProgram $out/bin/archive-home-files \
      --prefix PATH : "${finalAttrs.wrapperPath}" \
      --set-default GITLEAKS_CONFIG "${gitleaksConfig}" \
      --set-default AGE_RECIPIENTS "${lib.concatStringsSep "," keys}"
  '';

  vendorHash = "sha256-8kO79VawdMhdP5JczC9Yh1Dqva7EarOQHHCuuiWNF7U="; # same as other local go tools since they share go.mod
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

  subPackages = [
    "pkgs/local/${finalAttrs.pname}"
  ];

  env.CGO_ENABLED = 0;

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
      - Scans for secrets with gitleaks (follows symlinks to Nix store).
      - Encrypts the archive with age using all SSH public keys from config/ssh/keys.nix.
    '';
    mainProgram = "archive-home-files";
  };
})
