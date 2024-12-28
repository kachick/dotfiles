{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "ir";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    fd

    # Don't use these candidates
    #   - sed: Always forgot how to use
    #   - sd: Inactive
    #   - sad: Too much for filter
    ruby_3_4

    findutils # xargs
    gnugrep

    coreutils # cat
    mktemp
  ];
}
