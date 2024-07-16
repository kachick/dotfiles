{ inputs, pkgs, ... }:

# Using latest to avoid stable release and wayland problems https://github.com/wez/wezterm/issues/5340
inputs.wezterm-flake.packages.${pkgs.system}.default.overrideAttrs (prev: {
  nativeBuildInputs = prev.nativeBuildInputs ++ [ pkgs.makeWrapper ];

  # Wrap for https://github.com/wez/wezterm/pull/4777#issuecomment-2014478175
  postFixup = ''
    makeShellWrapper $out/bin/wezterm $out/bin/wezterm-wrapped \
        --set WAYLAND_DISPLAY 1
  '';

  meta = prev.meta // {
    mainProgram = "wezterm-wrapped";
  };
})
