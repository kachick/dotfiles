{
  stdenvNoCC,
  bottom,
  desktop-file-utils,
}:

stdenvNoCC.mkDerivation {
  inherit (bottom) pname version meta;

  # Copying original package should be better than overriding here to leverage official binary cache
  src = bottom;

  nativeBuildInputs = [
    desktop-file-utils
  ];

  installPhase = ''
    mkdir -p "$out/share/icons/hicolor/512x512/apps"
    cp -r $src/* $out/
    install -Dm444 ${./bottom.png} -t "$out/share/icons/hicolor/512x512/apps/"
  '';

  # Fix GH-1215.
  # Also require https://github.com/ClementTsang/bottom/pull/1749 to pass validations
  postFixup = ''
    desktop-file-edit "$out/share/applications/bottom.desktop" \
      --set-key='Icon' --set-value='btm' \
      --set-key='Version' --set-value='1.5' \
      --set-key='Categories' --set-value='ConsoleOnly;Monitor;'
  '';
}
