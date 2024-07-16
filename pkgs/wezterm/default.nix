{ wezterm, pkgs, ... }:

pkgs.writeShellApplication {
  name = "wezterm";
  # Wrap for https://github.com/wez/wezterm/pull/4777#issuecomment-2014478175
  text = ''
    export WAYLAND_DISPLAY=1
    wezterm "$@"
  '';
  runtimeInputs = [
    # Using latest to avoid stable release and wayland problems https://github.com/wez/wezterm/issues/5340
    wezterm
  ];
}
