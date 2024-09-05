{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "zj";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    coreutils
    zellij
  ];
  runtimeEnv = {
    ZELLIJ_DEFAULT_LAYOUT_PATH = "${../../config/zellij/layouts/regular.kdl}";
  };
}
