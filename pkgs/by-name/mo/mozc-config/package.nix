{
  lib,
  buildGo127Module,
  makeWrapper,
  mozc,
  protobuf,
  ibus,
  procps,
  ...
}:

let
  keymapPath = ../../../../config/mozc/keymap-msime-customized.txt;
in
buildGo127Module (finalAttrs: {
  pname = "mozc-config";
  version = "0.1.0";

  __structuredAttrs = true;

  vendorHash = null;

  src =
    with lib.fileset;
    toSource {
      root = ../../../../.;
      fileset = unions [
        ../../../../go.mod
        ../../../../internal/configsync
        ./.
      ];
    };

  subPackages = [ "pkgs/by-name/mo/${finalAttrs.pname}" ];

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
  ];

  nativeBuildInputs = [
    makeWrapper
    protobuf
  ];

  # Copy only config.proto instead of referencing mozc.src directly,
  # keeping the 160 MiB Mozc source tree out of the runtime closure.
  postInstall = ''
    install -Dm444 ${mozc.src}/src/protocol/config.proto \
      $out/share/${finalAttrs.pname}/proto/protocol/config.proto

    $out/bin/${finalAttrs.pname} encode \
      --proto-dir $out/share/${finalAttrs.pname}/proto \
      --keymap ${keymapPath} \
      --output $out/share/${finalAttrs.pname}/config1.db

    wrapProgram $out/bin/${finalAttrs.pname} \
      --set-default MOZC_PROTO_DIR $out/share/${finalAttrs.pname}/proto \
      --set-default MOZC_EXPECTED_CONFIG_DB $out/share/${finalAttrs.pname}/config1.db \
      --prefix PATH : ${
        lib.makeBinPath [
          protobuf
          ibus
          procps
        ]
      }
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck

    dumped="$($out/bin/${finalAttrs.pname} dump $out/share/${finalAttrs.pname}/config1.db)"
    grep -F "session_keymap: CUSTOM" <<< "$dumped" > /dev/null
    grep -F "Muhenkan" <<< "$dumped" > /dev/null
    grep -F "Ctrl Space" <<< "$dumped" > /dev/null
    $out/bin/${finalAttrs.pname} diff $out/share/${finalAttrs.pname}/config1.db

    runHook postInstallCheck
  '';

  meta = {
    description = "Inspect, diff, generate, and reload Mozc user configuration (config1.db)";
    license = lib.licenses.mit;
    mainProgram = finalAttrs.pname;
  };
})
