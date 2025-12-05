{
  lib,
  stdenv,
  buildGoModule, # Keep same toolset as lima package
  callPackage,
  apple-sdk_15,
  findutils,
  pkgs,
}:

let
  inherit (pkgs.my) lima;
in
buildGoModule (finalAttrs: {
  pname = "lima-additional-guestagents";

  # Because agents must use the same version as lima, lima's updateScript should also update the shared src.
  # nixpkgs-update: no auto update
  inherit (callPackage ../lima/source.nix { }) version src vendorHash; # Loading external package files is progibit in nixpkgs. However it is okay in my dotfiles :)

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    apple-sdk_15
  ];

  # Basically needless because forcing by upstream: https://github.com/lima-vm/lima/blob/v2.0.2/Makefile#L393-L399
  # However clarifying the value to avoid confusion and future regressions by changes likely: https://github.com/NixOS/nixpkgs/pull/458867
  env.CGO_ENABLED = "0";

  buildPhase =
    let
      makeFlags = [
        "VERSION=v${finalAttrs.version}"
        "CC=${stdenv.cc.targetPrefix}cc"
      ];
    in
    ''
      runHook preBuild

      make ${lib.escapeShellArgs makeFlags} additional-guestagents

      runHook postBuild
    '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r _output/* $out

    runHook postInstall
  '';

  nativeInstallCheckInputs = [
    findutils
  ];
  doInstallCheck = true;

  # Guest agents for the host's architecture are only in the "lima" package. So, we can't test this by running the binary.
  installCheckPhase = ''
    runHook preInstallCheck

    [[ "$(find "$out/share" -type f -name 'lima-guestagent.Linux-*.gz' | wc -l)" -ge 5 ]]

    runHook postInstallCheck
  '';

  meta = lima.meta // {
    description = "Lima Guest Agents for emulating non-native architectures";
    longDescription = ''
      This package should only be used when your guest's architecture differs from the host's.

      To enable its functionality in `limactl`, use `lima-full` package.
      Typically, you won't need to directly add this package to your *.nix files.
    '';
  };
})
