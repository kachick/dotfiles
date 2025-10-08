{
  lib,
  stdenvNoCC,
  fetchzip,
  versionCheckHook,
}:

let
  version = "0.7.1";
  # See https://github.com/boxdot/gurk-rs/releases for latest
  sources = {
    x86_64-linux = fetchzip {
      # Musl version is now a static-linked binary, so it works on NixOS out of the box.
      # https://github.com/boxdot/gurk-rs/issues/149#issuecomment-1294063051
      url = "https://github.com/boxdot/gurk-rs/releases/download/v${version}/gurk-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-AuMmE97CexJoD7uKTSgwjbOC2mS6bsacZxXmB8xQEsg=";
    };

    x86_64-darwin = fetchzip {
      url = "https://github.com/boxdot/gurk-rs/releases/download/v${version}/gurk-x86_64-apple-darwin.tar.gz";
      hash = "sha256-Js+m2A2ZRDAb08NUualcRDUqGN8rYWvJequ0lxOvAyo=";
    };
  };
  mainProgram = "gurk";
  system = stdenvNoCC.hostPlatform.system;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "gurk-rs-bin";
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
    description = "Signal Messenger client for terminal";
    longDescription = ''
      Nixpkgs version bumps often fail because this package’s crate setup isn’t very standard.
      Especially version 0.7.1 updating is stopped over 4 months.
      I may address it again after merging https://github.com/NixOS/nixpkgs/pull/387337.
    '';
    homepage = "https://github.com/boxdot/gurk-rs";
    license = lib.licenses.agpl3Only;
    # Upstream also provides other binaries, this restriction is from my laziness
    # Reconsider when addressing GH-1122
    platforms = lib.platforms.x86_64;
    priority = 10; # 5 by default. Prefer src built if exist
  };
})
