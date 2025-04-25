{
  lib,
  appimageTools,
  fetchzip,
}:

let
  pname = "shogihome";
  version = "1.22.1";
  zip = fetchzip {
    url = "https://github.com/sunfish-shogi/shogihome/releases/download/v${version}/release-v${version}-linux.zip";
    hash = "sha256-ArLhu286sFW1qZgmZl/TyAERiDuNbfWt0bKeGWfm//0=";
    stripRoot = false;
  };
  src = "${zip}/ShogiHome-${version}.AppImage";
  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version;

  src = "${zip}/ShogiHome-${version}.AppImage";

  # FIXME: Does not appeared in GNOME :<
  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/electron-shogi.desktop -t $out/share/applications
    cp ${appimageContents}/electron-shogi.png $out/share
  '';

  meta = {
    description = "Shogi Frontend";
    homepage = "https://github.com/sunfish-shogi/shogihome";
    license = with lib.licenses; [
      mit
      asl20 # for icons
    ];
    maintainers = with lib.maintainers; [
      kachick
    ];
  };
}
