{ wezterm, pkgs, ... }:

wezterm.overrideAttrs (
  final: prev: {
    nativeBuildInputs = prev.nativeBuildInputs ++ [ pkgs.makeWrapper ];

    # Wrap for https://github.com/wez/wezterm/pull/4777#issuecomment-2014478175
    postFixup = ''
      makeShellWrapper $out/bin/${prev.meta.mainProgram} $out/bin/${final.meta.mainProgram} \
          --set WAYLAND_DISPLAY 1
    '';

    meta = prev.meta // {
      mainProgram = "${prev.meta.mainProgram}-wrapped";
    };
  }
)
