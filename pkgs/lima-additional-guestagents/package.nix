{
  pkgs,
  findutils,
}:

let
  inherit (pkgs.unstable) buildGo126Module; # Keep same toolset as lima package
  inherit (pkgs.my) lima;
in
buildGo126Module (finalAttrs: {
  pname = "lima-additional-guestagents";

  inherit (lima) version src vendorHash;

  # This is mainly not needed because the upstream repository forces the value:
  #   - https://github.com/lima-vm/lima/blob/v2.0.2/Makefile#L393-L399
  # However, clarifying the value prevents confusion and specifically guards against regressions, such as the one that previously occurred:
  #   - https://github.com/NixOS/nixpkgs/pull/458867
  env.CGO_ENABLED = "0";

  buildPhase = ''
    runHook preBuild

    make additional-guestagents

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
