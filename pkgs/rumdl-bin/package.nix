{
  lib,
  stdenvNoCC,
  fetchzip,
  versionCheckHook,
}:

let
  version = "0.0.154";
  # See https://github.com/rvben/rumdl/releases for latest
  sources = {
    x86_64-linux = fetchzip {
      url = "https://github.com/rvben/rumdl/releases/download/v${version}/rumdl-v${version}-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-oL32jPS3latFf+MP9++ufGtyQIVZyMpvEZJlw+fXH2Q=";
    };
  };
  mainProgram = "rumdl";
  system = stdenvNoCC.hostPlatform.system;
in

stdenvNoCC.mkDerivation (finalAttrs: {
  # Build from source PR is: https://github.com/NixOS/nixpkgs/pull/446292
  pname = "rumdl-bin";
  inherit version;

  src = sources.${system} or (throw "Unsupported system: ${system}");

  buildPhase = ''
    mkdir -p "$out/bin"
  '';

  installPhase = ''
    cp -rs "$src"/* "$out/bin"
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  doInstallCheck = true;
  versionCheckProgram = "${placeholder "out"}/bin/${mainProgram}";
  versionCheckProgramArg = "--version";

  meta = {
    inherit mainProgram;
    description = "Markdown Linter";
    homepage = "https://github.com/rvben/rumdl";
    sourceProvenance = with lib.sourceTypes; [
      binaryBytecode
    ];
    license = lib.licenses.mit;
    # Upstream also provides other binaries, this restriction is from my laziness
    # Reconsider when addressing GH-1122
    platforms = lib.intersectLists lib.platforms.x86_64 lib.platforms.linux;
    priority = 10; # 5 by default. Prefer src built if exist
    maintainers = with lib.maintainers; [
      kachick
    ];
  };
})
