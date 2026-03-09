{
  lib,
  stdenv,
  onnxruntime,
  fetchFromGitHub,
  fetchzip,
  runCommand,
}:

let
  version = "20230224";
  repo = "hcpu_shogi";
  model = fetchzip {
    url = "https://github.com/toame/${repo}/releases/download/${version}/model-${version}.zip";
    hash = "sha256-Lptn2gQibEOf/qY5LO3V07o2RbImbsfCmtJUyh3kAEU=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "hcpu_shogi";
  inherit version;

  src = fetchFromGitHub {
    inherit repo;
    owner = "kachick"; # Upstream appears not supporting onnxruntime on Linux, so I forked
    rev = "43578edfa8dc994fec80c6d2d97780292d318bf4";
    hash = "sha256-ARkpYL1zk/vWjBUDgfZ4iEdb8F6VpGdDqh8xR4XJgvE=";
  };

  buildInputs = [
    onnxruntime
  ];

  buildPhase = ''
    runHook preBuild
    make -f Makefile.onnx -j$NIX_BUILD_CORES
    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp bin/hcpu_shogi $out/bin/hcpu_shogi

    mkdir -p $out/share/hcpu_shogi
    cp ${model}/model_${version}.onnx $out/share/hcpu_shogi/
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    echo 'usi' | $out/bin/hcpu_shogi | grep -q 'usiok'

    (
      echo "setoption name DNN_Model value $out/share/hcpu_shogi/model_${version}.onnx"
      echo 'isready'
    ) | $out/bin/hcpu_shogi | grep -q 'readyok'
  '';

  passthru.tests = {
    search =
      runCommand "${finalAttrs.pname}-test-search"
        {
          nativeBuildInputs = [ finalAttrs.finalPackage ];
        }
        ''
          # Test if the engine can actually generate a move
          (
            echo "setoption name DNN_Model value ${finalAttrs.finalPackage}/share/hcpu_shogi/model_${version}.onnx"
            echo 'isready'
            echo 'position startpos'
            echo 'go movetime 1000'
            sleep 2
            echo 'quit'
          ) | hcpu_shogi | tee $out | grep -q 'bestmove'
        '';
  };

  meta = {
    description = "USI shogi engine for handicap games";
    homepage = "https://github.com/toame/hcpu_shogi";
    license = lib.licenses.gpl3Only;
    platforms = with lib.platforms; linux ++ windows;
    mainProgram = "hcpu_shogi";
    maintainers = with lib.maintainers; [
      kachick
    ];
  };
})
