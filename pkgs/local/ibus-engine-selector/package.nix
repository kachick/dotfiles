{
  lib,
  pkgs,
  makeWrapper,
  fzf,
  ibus,
  ...
}:

let
  configPath = ../../../config/mozc/ibus_config.textproto;
  inherit (pkgs.unstable) buildGo126Module;
in
buildGo126Module (finalAttrs: {
  pname = "ibus-engine-selector";
  version = "0.1.0";

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

  vendorHash = "sha256-bf4ZygJK7cNWkNxs97pOchT8x2EPeW0VQ1CMoYyoAHo=";

  subPackages = [ "pkgs/local/${finalAttrs.pname}" ];

  ldflags = [ "-s" ];

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/ibus-engine-selector \
      --set-default IBUS_CONFIG_TEXTPROTO ${configPath} \
      --prefix PATH : ${
        lib.makeBinPath [
          fzf
          ibus
        ]
      }
  '';

  passthru.shared-gomod = true;

  meta = {
    description = "Select IBus engine with fzf";
    longDescription = ''
      This tool is provided because Mozc's configuration management is limited.
      Especially keyboard layout settings (like ANSI vs JIS) are not automatically loaded from the config file via CLI or standard rc files.
      Usually, one needs to import/configure them via GUI (mozc_tool) and then run `ibus write-cache; ibus restart`.
      This process is extremely tedious in environments like LiveCDs or during fresh installations where quick setup is preferred.
    '';
    license = lib.licenses.mit;
    mainProgram = finalAttrs.pname;
  };
})
