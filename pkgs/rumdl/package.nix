{
  lib,
  stdenvNoCC,
  fetchzip,
  versionCheckHook,
}:

let
  version = "0.0.147";
  # See https://github.com/rvben/rumdl/releases for latest
  sources = {
    x86_64-linux = fetchzip {
      url = "https://github.com/rvben/rumdl/releases/download/v${version}/rumdl-v${version}-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-jUt0EOKx/FZ2WNHCHshMAS0K2hFRHcKJ34ono6a2pyM=";
    };
  };
  mainProgram = "rumdl";
  system = stdenvNoCC.hostPlatform.system;
in

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "rumdl";
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
    longDescription = ''
      I sent build from source PR into upstream. See https://github.com/NixOS/nixpkgs/pull/446292
    '';
    homepage = "https://github.com/rvben/rumdl";
    license = lib.licenses.mit;
    # Upstream also provides other binaries, this restriction is from my laziness
    # Reconsider when addressing GH-1122
    platforms = lib.intersectLists lib.platforms.x86_64 lib.platforms.linux;
    maintainers = with lib.maintainers; [
      kachick
    ];
  };
})
