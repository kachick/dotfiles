{
  stdenvNoCC,
  symlinkJoin,
  pkgs,
  testers,
  writeText,
  runCommand,
  writableTmpDirAsHomeHook,
  jq,
}:

let
  inherit (pkgs.my) lima lima-additional-guestagents lima-full;
in
symlinkJoin {
  inherit (lima) version;

  pname = "lima-full";

  paths = [
    lima
    lima-additional-guestagents
  ];

  # symlinkJoin does not run InstallCheckPhase even if defined

  passthru = {
    tests = lima.passthru.tests // {
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
