{
  lib,
  pkgs,
  stdenvNoCC,
  fetchurl,
  _7zz,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "tanuki-hao";
  version = "2023-05-08";

  src = fetchurl {
    # - Compatible with NNUE_halfkp_256x2_32_32 such as Suisho5, nixpkgs's YaneuraOu binary can't open Lí's NNUE_halfkp_1024x2_8_32 format
    # - Stronger than Suisho5
    # - Available under FOSS license
    url = "https://github.com/nodchip/tanuki-/releases/download/tanuki-.halfkp_256x2-32-32.${finalAttrs.version}/tanuki-.halfkp_256x2-32-32.${finalAttrs.version}.7z";
    hash = "sha256-8W3GbFKYV78I/OjO5PHlOmmTKXZEEAJnpszM1i5D27o=";
  };

  dontUnpack = true;

  nativeBuildInputs = [
    _7zz
  ];

  buildPhase = ''
    7zz x "$src"
  '';

  # Almost 25MiB after unarchived
  installPhase = ''
    mkdir -p "$out/share"
    cp -r ./eval "$out/share"
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    pkgs.unstable.yaneuraou
  ];
  installCheckPhase = ''
    runHook preInstallCheck

    usi_command="setoption name EvalDir value "$out/share/eval"
    isready
    go byoyomi 1000
    wait"
    usi_output="$(YaneuraOu <<< "$usi_command")"
    echo "$usi_output"
    [[ "$usi_output" == *'bestmove'* ]]

    runHook postInstallCheck
  '';

  meta = {
    description = "Shogi NNUE evaluation file";
    homepage = "https://github.com/nodchip/tanuki-/releases/tag/tanuki-.halfkp_256x2-32-32.2023-05-08";
    # https://github.com/nodchip/tanuki-/blob/e57d67cb596c47ec70745a24e65ed25182a5726a/Copying.txt
    license = lib.licenses.gpl3Only;
  };
})
