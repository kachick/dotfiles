{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "check_nixf";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    nixf
    git
    findutils # `xargs`
    gnugrep
  ];
  # Removing "errexit" for using grep to check empty result. See https://github.com/kachick/times_kachick/issues/278
  bashOptions = [
    "nounset"
    "pipefail"
  ];
  meta = {
    description = "Wrapper for nixf-tidy. See GH-777";
  };
}
