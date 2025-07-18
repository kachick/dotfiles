{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "toggle-wofi";
  # Don't fix wofi path. Just specifying with the name should be useful here
  runtimeInputs = with pkgs; [
    procps # `pkill`
  ];
  # Required to remove `errexit` for `||` operator
  bashOptions = [
    "nounset"
    "pipefail"
  ];
  text = builtins.readFile ./${name}.bash;
  meta = {
    description = "Realize combo to switch launchers for replacement of unusable <Alt>space overlay-key in GNOME";
  };
}
