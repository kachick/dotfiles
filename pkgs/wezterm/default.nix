{
  wezterm,
  lib,
  pkgs,
  ...
}:

pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "wezterm";
  version = wezterm.version;

  nativeBuildInputs = [
    wezterm
    pkgs.makeWrapper
  ];

  # https://github.com/NixOS/nixpkgs/issues/23099#issuecomment-964024407
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    makeShellWrapper ${lib.getExe wezterm} $out/bin/wezterm \
        --set WAYLAND_DISPLAY 1

    runHook postInstall
  '';

  meta = wezterm.meta;
})
