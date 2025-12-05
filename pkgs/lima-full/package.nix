{
  stdenvNoCC,
  pkgs,
  testers,
  writeText,
  runCommand,
  writableTmpDirAsHomeHook,
  versionCheckHook,
  jq,
}:

let
  inherit (pkgs.my) lima lima-additional-guestagents lima-full;
in
stdenvNoCC.mkDerivation {
  inherit (lima) version;

  pname = "lima-full";

  src = lima;

  installPhase = ''
    mkdir -p "$out/share/lima"
    cp -rs "$src/." "$out/"
    cp -rs '${lima-additional-guestagents}/share/lima/.' "$out/share/lima/"
  '';

  nativeInstallCheckInputs = [
    # Workaround for: "panic: $HOME is not defined" at https://github.com/lima-vm/lima/blob/cb99e9f8d01ebb82d000c7912fcadcd87ec13ad5/pkg/limayaml/defaults.go#L53
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  doInstallCheck = true;
  versionCheckProgram = "${placeholder "out"}/bin/limactl";
  versionCheckProgramArg = "--version";
  versionCheckKeepEnvironment = [ "HOME" ];

  passthru = {
    tests =
      let
        arch = stdenvNoCC.hostPlatform.parsed.cpu.name;
      in
      {
        # `nix build .#lima-full.passthru.tests.additionalAgents`
        additionalAgents = testers.testEqualContents {
          assertion = "limactl also detects additional guest agents if specified";
          expected = writeText "expected" ''
            true
            true
          '';
          actual =
            runCommand "actual"
              {
                nativeBuildInputs = [
                  writableTmpDirAsHomeHook
                  lima-full
                  jq
                ];
              }
              ''
                limactl info | jq '.guestAgents | has("${arch}")' >>"$out"
                limactl info | jq '.guestAgents | length >= 2' >>"$out"
              '';
        };
      };
  };

  meta = lima.meta // {
    description = "Lima and the additional guest agents";
  };
}
