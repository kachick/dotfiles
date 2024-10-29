{ pkgs, edge-pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "check_nixf";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs =
    with pkgs;
    [
      git
      findutils # `xargs`
      gnugrep
    ]
    ++ [ edge-pkgs.nixf ];
  # Removing "errexit" for using grep to check empty result. See https://github.com/kachick/times_kachick/issues/278
  bashOptions = [
    "nounset"
    "pipefail"
  ];
  meta = {
    description = "Wrapper for nixf-tidy. See GH-777";
  };
}
