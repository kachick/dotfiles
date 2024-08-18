{
  stdenv,
  lib,
  autoPatchelfHook,
  copyDesktopItems,
  dbus,
  dpkg,
  fetchurl,
  gtk3,
  libpcap,
  makeDesktopItem,
  makeWrapper,
  nftables,
}:

# Patched because of nixpkgs does not include latest and I would try this ver when addressing GH-749
# https://github.com/NixOS/nixpkgs/blob/7de4869f8a4c21b1a2831df721e3d4599365ee69/pkgs/tools/networking/cloudflare-warp/default.nix
stdenv.mkDerivation rec {
  pname = "cloudflare-warp";
  version = "2024.6.497";

  suffix =
    {
      aarch64-linux = "arm64";
      x86_64-linux = "amd64";
    }
    .${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  src = fetchurl {
    url = "https://pkg.cloudflareclient.com/pool/noble/main/c/cloudflare-warp/cloudflare-warp_${version}-1_${suffix}.deb";
    hash =
      {
        aarch64-linux = "sha256-j0D1VcPCJpp0yoK6GjuKKwTVNEqKgr9+6X1AfBbsXAg=";
        x86_64-linux = "sha256-y+1TQ/QzzjkorSscB2+QBYR81IowKWcgSoUm1Nz9Gts=";
      }
      .${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    dbus
    gtk3
    libpcap
    stdenv.cc.cc.lib
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "com.cloudflare.WarpCli";
      desktopName = "Cloudflare Zero Trust Team Enrollment";
      categories = [
        "Utility"
        "Security"
        "ConsoleOnly"
      ];
      noDisplay = true;
      mimeTypes = [ "x-scheme-handler/com.cloudflare.warp" ];
      exec = "warp-cli teams-enroll-token %u";
      startupNotify = false;
      terminal = true;
    })
  ];

  autoPatchelfIgnoreMissingDeps = [ "libpcap.so.0.8" ];

  installPhase = ''
    runHook preInstall

    mv usr $out
    mv bin $out
    mv etc $out
    patchelf --replace-needed libpcap.so.0.8 ${libpcap}/lib/libpcap.so $out/bin/warp-dex
    mv lib/systemd/system $out/lib/systemd/
    substituteInPlace $out/lib/systemd/system/warp-svc.service \
      --replace "ExecStart=" "ExecStart=$out"
    substituteInPlace $out/lib/systemd/user/warp-taskbar.service \
      --replace "ExecStart=" "ExecStart=$out"

    cat >>$out/lib/systemd/user/warp-taskbar.service <<EOF

    [Service]
    BindReadOnlyPaths=$out:/usr:
    EOF

    runHook postInstall
  '';

  postInstall = ''
    wrapProgram $out/bin/warp-svc --prefix PATH : ${lib.makeBinPath [ nftables ]}
  '';

  meta = with lib; {
    description = "Replaces the connection between your device and the Internet with a modern, optimized, protocol";
    homepage = "https://pkg.cloudflareclient.com/packages/cloudflare-warp";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    mainProgram = "warp-cli";
    maintainers = with maintainers; [
      devpikachu
      marcusramberg
      kachick
    ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
