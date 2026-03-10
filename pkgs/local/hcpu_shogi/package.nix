{
  lib,
  stdenv,
  onnxruntime,
  fetchzip,
  fetchFromGitHub,
  runCommand,
  local,
}:

let
  version = "20230224";
  model = fetchzip {
    url = "https://github.com/toame/hcpu_shogi/releases/download/${version}/model-${version}.zip";
    hash = "sha256-Lptn2gQibEOf/qY5LO3V07o2RbImbsfCmtJUyh3kAEU=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "hcpu_shogi";
  inherit version;

  src = fetchFromGitHub {
    owner = "kachick"; # Upstream appears not supporting onnxruntime on Linux, so I forked
    repo = "hcpu_shogi";
    rev = "linux-onnx-and-nix"; # https://github.com/toame/hcpu_shogi/pull/1
    hash = "sha256-IDQ44c3SYqak6+52ZiLH93VK9DK9rsLsS81Na/bMWhY=";
  };

  buildInputs = [
    onnxruntime
  ];

  makeFlags = [
    "-C usi"
    "ONNXRUNTIME=1"
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 usi/bin/usi $out/bin/hcpu_shogi
    install -Dm444 ${model}/model_${version}.onnx $out/share/hcpu_shogi/model_${version}.onnx

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    usi_output="$($out/bin/hcpu_shogi <<EOF
    setoption name DNN_Model value $out/share/hcpu_shogi/model_${version}.onnx
    isready
    quit
    EOF
    )"
    [[ "$usi_output" == *"readyok"* ]]

    runHook postInstallCheck
  '';

  passthru.tests = {
    move =
      runCommand "${finalAttrs.pname}-test-move"
        {
          nativeBuildInputs = [
            local.hcpu_shogi
          ];
        }
        ''
          hcpu_shogi <<EOF > "$out"
          usi
          setoption name DNN_Model value ${finalAttrs.finalPackage}/share/hcpu_shogi/model_${version}.onnx
          isready
          position startpos
          go movetime 1000
          quit
          EOF

          [[ "$(< "$out")" == *"bestmove"* ]]
        '';
  };

  meta = {
    description = "USI shogi engine for handicap games";
    homepage = "https://github.com/toame/hcpu_shogi";
    license = lib.licenses.gpl3Only;
    platforms =
      let
        inherit (lib.platforms) x86_64 linux windows;
      in
      lib.intersectLists x86_64 (linux ++ windows);
    mainProgram = "hcpu_shogi";
  };
})
