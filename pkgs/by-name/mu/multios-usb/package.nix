{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  bash,
  coreutils,
  gnutar,
  xz,
  gptfdisk,
  util-linux,
  exfatprogs,
  dosfstools,
  gnugrep,
  gnused,
  rsync,
  e2fsprogs,
  ntfs3g,
  nix-update-script,
}:

# Personal fork of https://github.com/NixOS/nixpkgs/pull/563389 because it is unmerged.
# Drop this local package and switch to nixpkgs.multios-usb once the upstream PR is merged.

let
  runtimeDeps = [
    bash
    coreutils
    gnutar
    xz
    gptfdisk
    util-linux
    exfatprogs
    dosfstools
    gnugrep
    gnused
    rsync
    e2fsprogs
    ntfs3g
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "multios-usb";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "Mexit";
    repo = "MultiOS-USB";
    tag = "v${finalAttrs.version}";
    hash = "sha256-jZ+bPQKc45fiIAbTUeNwpla6yQXBUyICeciWcIsauR4=";
  };

  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ bash ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/multios-usb $out/bin
    cp -r . $out/share/multios-usb
    chmod +x $out/share/multios-usb/multios-usb.sh

    makeWrapper $out/share/multios-usb/multios-usb.sh $out/bin/multios-usb \
      --chdir $out/share/multios-usb \
      --prefix PATH : ${lib.makeBinPath runtimeDeps}

    runHook postInstall
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck

    $out/bin/multios-usb --help | grep -F 'default: "exfat"' >/dev/null

    runHook postInstallCheck
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        # nix-update does not pass --flake to child scripts: https://github.com/Mic92/nix-update/pull/330
        "--flake"
      ];
    };
  };

  meta = {
    description = "Boot operating systems directly from ISO/WIM images";
    homepage = "https://github.com/Mexit/MultiOS-USB";
    changelog = "https://github.com/Mexit/MultiOS-USB/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "multios-usb";
  };
})
